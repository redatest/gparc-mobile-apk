import 'package:flutter/material.dart';
import '../data/gparc_database.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Map<String, Object?>> structures = [];
  List<Map<String, Object?>> structureTotals = [];
  List<Map<String, Object?>> typeTotals = [];
  Map<String, int> metrics = {};
  int? selectedStructureId;
  bool busy = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<int> _count(String sql, [List<Object?> args = const []]) async {
    final rows = await GparcDatabase.instance.db.rawQuery(sql, args);
    return (rows.first['n'] as num?)?.toInt() ?? 0;
  }

  Future<void> _load() async {
    if (mounted) setState(() { busy = true; error = null; });
    try {
      final db = GparcDatabase.instance.db;
      final structureRows = await db.rawQuery('''
        SELECT id_str, lib_str
        FROM structures
        WHERE COALESCE(archiv, 'N') <> 'O'
        ORDER BY lib_str COLLATE NOCASE
      ''');

      final filter = selectedStructureId == null ? '' : ' AND m.id_str = ?';
      final args = selectedStructureId == null
          ? <Object?>[]
          : <Object?>[selectedStructureId];

      final total = await _count('''
        SELECT COUNT(*) AS n FROM materiel m
        WHERE COALESCE(m.archiv, 'N') <> 'O'$filter
      ''', args);
      final active = await _count('''
        SELECT COUNT(*) AS n FROM materiel m
        WHERE COALESCE(m.archiv, 'N') <> 'O'
          AND COALESCE(m.statut_mat, 'ES') = 'ES'$filter
      ''', args);
      final proposed = await _count('''
        SELECT COUNT(*) AS n FROM materiel m
        WHERE COALESCE(m.archiv, 'N') <> 'O'
          AND COALESCE(m.statut_mat, 'ES') = 'PR'$filter
      ''', args);
      final reformed = await _count('''
        SELECT COUNT(*) AS n FROM materiel m
        WHERE COALESCE(m.archiv, 'N') <> 'O'
          AND COALESCE(m.statut_mat, 'ES') = 'RF'$filter
      ''', args);
      final faults = await _count('''
        SELECT COUNT(*) AS n
        FROM panne p
        INNER JOIN materiel m ON m.id_mat = p.id_mat
        WHERE COALESCE(p.archiv, 'N') <> 'O'
          AND COALESCE(p.eta_pan, 'EP') IN ('EP', 'ER')
          AND COALESCE(m.archiv, 'N') <> 'O'$filter
      ''', args);

      final typeRows = await db.rawQuery('''
        SELECT COALESCE(NULLIF(TRIM(t.lib_typ_mat), ''), 'Type non renseigné') AS type,
               COUNT(*) AS total
        FROM materiel m
        LEFT JOIN type_mat t ON t.id_typ_mat = m.id_typ_mat
        WHERE COALESCE(m.archiv, 'N') <> 'O'$filter
        GROUP BY COALESCE(NULLIF(TRIM(t.lib_typ_mat), ''), 'Type non renseigné')
        ORDER BY total DESC, type COLLATE NOCASE
      ''', args);

      final byStructure = await db.rawQuery('''
        SELECT s.id_str, s.lib_str, COUNT(m.id_mat) AS total
        FROM structures s
        LEFT JOIN materiel m
          ON m.id_str = s.id_str AND COALESCE(m.archiv, 'N') <> 'O'
        WHERE COALESCE(s.archiv, 'N') <> 'O'
        GROUP BY s.id_str, s.lib_str
        ORDER BY total DESC, s.lib_str COLLATE NOCASE
      ''');

      if (!mounted) return;
      setState(() {
        structures = structureRows;
        structureTotals = byStructure;
        typeTotals = typeRows;
        metrics = {
          'total': total,
          'active': active,
          'faults': faults,
          'proposed': proposed,
          'reformed': reformed,
        };
        busy = false;
      });
    } catch (e) {
      if (mounted) setState(() { busy = false; error = 'Impossible de calculer les statistiques : $e'; });
    }
  }

  String get _selectedName {
    if (selectedStructureId == null) return 'Toutes les structures';
    for (final row in structures) {
      if (row['id_str'] == selectedStructureId) return '${row['lib_str'] ?? 'Structure'}';
    }
    return 'Structure sélectionnée';
  }

  @override
  Widget build(BuildContext context) {
    if (busy) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 36),
        const SizedBox(height: 12),
        Text(error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
      ]),
    ));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Statistiques du parc', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Analyse des équipements par structure et par catégorie.'),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            value: selectedStructureId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Structure',
              prefixIcon: Icon(Icons.account_tree_outlined),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Toutes les structures')),
              ...structures.map((row) => DropdownMenuItem<int?>(
                value: (row['id_str'] as num).toInt(),
                child: Text('${row['lib_str'] ?? 'Structure sans nom'}', overflow: TextOverflow.ellipsis),
              )),
            ],
            onChanged: (value) {
              setState(() => selectedStructureId = value);
              _load();
            },
          ),
          const SizedBox(height: 8),
          Text(_selectedName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF176B87))),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _Metric(label: 'Équipements', value: metrics['total'] ?? 0, icon: Icons.devices, color: const Color(0xFF247BA0)),
              _Metric(label: 'En service', value: metrics['active'] ?? 0, icon: Icons.check_circle_outline, color: const Color(0xFF258477)),
              _Metric(label: 'Pannes actives', value: metrics['faults'] ?? 0, icon: Icons.build_circle_outlined, color: const Color(0xFFD45B55)),
              _Metric(label: 'À réformer', value: metrics['proposed'] ?? 0, icon: Icons.pending_actions, color: const Color(0xFFE19A38)),
              _Metric(label: 'Réformés', value: metrics['reformed'] ?? 0, icon: Icons.archive_outlined, color: const Color(0xFF7A6AA6)),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('Répartition par type'),
          const SizedBox(height: 8),
          if (typeTotals.isEmpty)
            const _EmptyState(message: 'Aucun équipement pour cette sélection.')
          else
            ...typeTotals.map((row) {
              final count = (row['total'] as num).toInt();
              final total = metrics['total'] ?? 0;
              final ratio = total == 0 ? 0.0 : count / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('${row['type']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('$count  ·  ${(ratio * 100).toStringAsFixed(1)} %', style: const TextStyle(color: Color(0xFF60717D), fontSize: 12)),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0).toDouble(),
                      minHeight: 9,
                      backgroundColor: const Color(0xFFE6EDF1),
                      color: const Color(0xFF258477),
                    ),
                  ),
                ]),
              );
            }),
          if (selectedStructureId == null) ...[
            const SizedBox(height: 12),
            _sectionTitle('Par structure'),
            const SizedBox(height: 8),
            if (structureTotals.isEmpty)
              const _EmptyState(message: 'Aucune structure enregistrée.')
            else
              ...structureTotals.map((row) {
                final count = (row['total'] as num).toInt();
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE2F0F5),
                      foregroundColor: Color(0xFF176B87),
                      child: Icon(Icons.account_tree_outlined, size: 19),
                    ),
                    title: Text('${row['lib_str'] ?? 'Structure sans nom'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    onTap: () {
                      setState(() => selectedStructureId = (row['id_str'] as num).toInt());
                      _load();
                    },
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(radius: 15, backgroundColor: color.withValues(alpha: 0.13), foregroundColor: color, child: Icon(icon, size: 18)),
        const SizedBox(height: 7),
        Text('$value', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF203746))),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF657783))),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Center(child: Text(message, style: const TextStyle(color: Color(0xFF657783)))),
  );
}
