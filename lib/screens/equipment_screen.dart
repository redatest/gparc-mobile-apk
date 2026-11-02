import 'package:flutter/material.dart';
import '../data/gparc_database.dart';
import '../widgets/equipment_type_icon.dart';
import 'scanner_screen.dart';
import 'equipment_form_screen.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final controller = TextEditingController();
  String filter = 'all';
  List<Map<String, Object?>> rows = [];
  bool busy = true;

  @override
  void initState() {
    super.initState();
    controller.text = widget.initialQuery;
    load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => busy = true);
    final query = controller.text.trim();
    final data = query.isEmpty
        ? await GparcDatabase.instance.listEquipment(filter: filter)
        : await GparcDatabase.instance.searchEquipment(query);
    if (mounted) setState(() { rows = data; busy = false; });
  }

  Future<void> scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (code != null) {
      controller.text = code;
      await load();
    }
  }

  Future<void> addEquipment() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EquipmentFormScreen()),
    );
    if (created == true) await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addEquipment,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Inventaire, série, marque…',
                    ),
                    onChanged: (_) => load(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scanner',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Tous', 'all'),
                  _filterChip('En service', 'active'),
                  _filterChip('À réformer', 'proposed'),
                  _filterChip('Réformés', 'reform'),
                ],
              ),
            ),
          ),
          Expanded(
            child: busy
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? const Center(child: Text('Aucun matériel trouvé.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final item = rows[index];
                          final name = [
                            item['marque_mat'],
                            item['lib_typ_mat'],
                          ].where((value) => value != null && '$value'.isNotEmpty).join(' · ');
                          final user = [
                            item['nom_uti'],
                            item['pnom_uti'],
                          ].where((value) => value != null && '$value'.isNotEmpty).join(' ');
                          final subtitle = [
                            name,
                            item['lib_str'],
                            if (user.isNotEmpty) user,
                          ].where((value) => value != null && '$value'.isNotEmpty).join(' • ');
                          final statusColor = _statusColor(item['statut_mat']);

                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColor.withValues(alpha: 0.13),
                                foregroundColor: statusColor,
                                child: Icon(EquipmentTypeIcon.forType(item['lib_typ_mat'])),
                              ),
                              title: Text(
                                '\${item['num_inv'] ?? 'Sans inventaire'}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(subtitle),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _status(item['statut_mat']),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              onTap: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => _EquipmentDetails(item: item),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: filter == value,
        onSelected: (_) {
          setState(() => filter = value);
          load();
        },
      ),
    );
  }

  Color _statusColor(Object? value) => switch (value) {
    'ES' => const Color(0xFF258477),
    'PR' => const Color(0xFFE19A38),
    'RF' => const Color(0xFF7A6AA6),
    _ => const Color(0xFF247BA0),
  };

  String _status(Object? value) => switch (value) {
    'ES' => 'En service',
    'PR' => 'À réformer',
    'RF' => 'Réformé',
    _ => '—',
  };
}

class _EquipmentDetails extends StatelessWidget {
  const _EquipmentDetails({required this.item});

  final Map<String, Object?> item;

  @override
  Widget build(BuildContext context) {
    final entries = <String, Object?>{
      'N° inventaire': item['num_inv'],
      'N° série': item['num_ser'],
      'Marque': item['marque_mat'],
      'Type': item['lib_typ_mat'],
      'Structure': item['lib_str'],
      'Utilisateur': [
        item['nom_uti'],
        item['pnom_uti'],
      ].where((value) => value != null).join(' '),
      'État': item['etat_mat'],
      'Statut': item['statut_mat'],
      'Processeur': item['cpu'],
      'RAM': item['ram'],
      'Disque': item['disk'],
      'Système': item['se'],
      'Adresse IP': item['ip'],
      'Observation': item['obs_mat'],
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fiche matériel', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...entries.entries
                .where((entry) => entry.value != null && '\${entry.value}'.isNotEmpty)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 115,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(child: Text('\${entry.value}')),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
