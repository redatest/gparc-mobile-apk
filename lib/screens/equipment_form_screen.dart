import 'package:flutter/material.dart';
import '../data/gparc_database.dart';

class EquipmentFormScreen extends StatefulWidget {
  const EquipmentFormScreen({super.key});
  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _key = GlobalKey<FormState>();
  final _inventory = TextEditingController();
  final _serial = TextEditingController();
  final _brand = TextEditingController();
  final _cpu = TextEditingController();
  final _ram = TextEditingController();
  final _disk = TextEditingController();
  final _os = TextEditingController();
  final _notes = TextEditingController();
  List<Map<String,Object?>> structures = [];
  List<Map<String,Object?>> types = [];
  List<Map<String,Object?>> users = [];
  int? structureId;
  int? typeId;
  int? userId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    final db = GparcDatabase.instance.db;
    final s = await db.query('structures', columns: ['id_str','lib_str'], where: "COALESCE(archiv,'N')='N'", orderBy: 'lib_str');
    final t = await db.query('type_mat', columns: ['id_typ_mat','lib_typ_mat'], where: "COALESCE(archiv,'N')='N'", orderBy: 'lib_typ_mat');
    final u = await db.query('utilisateurs', columns: ['id_uti','nom_uti','pnom_uti'], where: "COALESCE(archiv,'N')='N'", orderBy: 'nom_uti');
    if (mounted) setState(() { structures=s; types=t; users=u; });
  }

  @override
  void dispose() {
    for (final c in [_inventory,_serial,_brand,_cpu,_ram,_disk,_os,_notes]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final db = GparcDatabase.instance.db;
      await db.transaction((txn) async {
        final id = await txn.insert('materiel', {
          'id_str': structureId,
          'id_typ_mat': typeId,
          'marque_mat': _brand.text.trim(),
          'num_inv': _inventory.text.trim(),
          'num_ser': _serial.text.trim(),
          'etat_mat': 'BON',
          'statut_mat': 'ES',
          'etat_reforme': 'AUCUNE',
          'cpu': _cpu.text.trim(),
          'ram': int.tryParse(_ram.text.trim()),
          'disk': int.tryParse(_disk.text.trim()),
          'se': _os.text.trim(),
          'obs_mat': _notes.text.trim(),
          'id_uti': userId,
          'dat_mod': DateTime.now().toIso8601String(),
        });
        if (structureId != null || userId != null) {
          await txn.insert('affect_mat', {
            'id_mat': id,
            'id_str': structureId,
            'id_typ_mat': typeId,
            'num_inv': _inventory.text.trim(),
            'num_ser': _serial.text.trim(),
            'id_uti': userId,
            'action_aff': 'NOUVELLE_AFFECTATION',
            'obs_aff': 'Affectation initiale depuis GParc Mobile',
          });
        }
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enregistrement impossible : $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nouveau matériel')),
    body: Form(key: _key, child: ListView(padding: const EdgeInsets.all(16), children: [
      TextFormField(controller: _inventory, decoration: const InputDecoration(labelText: 'Numéro d’inventaire *'), validator: (v) => v==null || v.trim().isEmpty ? 'Champ obligatoire' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _serial, decoration: const InputDecoration(labelText: 'Numéro de série'),),
      const SizedBox(height: 12),
      TextFormField(controller: _brand, decoration: const InputDecoration(labelText: 'Marque')),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(value: typeId, decoration: const InputDecoration(labelText: 'Type de matériel'), items: types.map((r)=>DropdownMenuItem(value:r['id_typ_mat'] as int,child:Text('${r['lib_typ_mat']}'))).toList(), onChanged:(v)=>setState(()=>typeId=v)),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(value: structureId, decoration: const InputDecoration(labelText: 'Structure'), items: structures.map((r)=>DropdownMenuItem(value:r['id_str'] as int,child:Text('${r['lib_str']}'))).toList(), onChanged:(v)=>setState(()=>structureId=v)),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(value: userId, decoration: const InputDecoration(labelText: 'Utilisateur affecté'), items: users.map((r)=>DropdownMenuItem(value:r['id_uti'] as int,child:Text('${r['pnom_uti']??''} ${r['nom_uti']??''}'))).toList(), onChanged:(v)=>setState(()=>userId=v)),
      const SizedBox(height: 12),
      TextFormField(controller: _cpu, decoration: const InputDecoration(labelText: 'Processeur')),
      const SizedBox(height: 12),
      Row(children:[Expanded(child:TextFormField(controller:_ram,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'RAM (Go)'))),const SizedBox(width:12),Expanded(child:TextFormField(controller:_disk,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Disque (Go)')))]),
      const SizedBox(height: 12),
      TextFormField(controller: _os, decoration: const InputDecoration(labelText: 'Système d’exploitation')),
      const SizedBox(height: 12),
      TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Observation')),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: saving ? null : _save, icon: saving ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.save), label: const Text('Enregistrer')),
    ])),
  );
}
