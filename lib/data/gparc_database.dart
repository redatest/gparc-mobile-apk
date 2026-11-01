import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class GparcDatabase {
  GparcDatabase._();
  static final instance = GparcDatabase._();
  Database? _db;
  Database get db => _db!;

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = p.join(dir.path, 'gparc.db');
    _db = await openDatabase(file, version: 1, onCreate: _createSchema,
      onConfigure: (database) async => database.execute('PRAGMA foreign_keys = ON'));
  }

  Future<void> _createSchema(Database db, int version) async {
    final statements = <String>[
      '''CREATE TABLE structures (id_str INTEGER PRIMARY KEY AUTOINCREMENT, cod_str TEXT NOT NULL, lib_str TEXT NOT NULL, id_str_mere INTEGER, archiv TEXT DEFAULT 'N', dat_cre DATETIME DEFAULT CURRENT_TIMESTAMP, etat_reforme TEXT DEFAULT 'AUCUNE', motif_reforme TEXT, date_proposition_reforme DATE, date_validation_reforme DATE, date_reforme DATE, decision_reforme TEXT, pv_reforme TEXT)''',
      '''CREATE TABLE type_mat (id_typ_mat INTEGER PRIMARY KEY AUTOINCREMENT, cod_typ_mat TEXT NOT NULL, lib_typ_mat TEXT NOT NULL, archiv TEXT DEFAULT 'N', dat_cre DATETIME DEFAULT CURRENT_TIMESTAMP)''',
      '''CREATE TABLE model_mat (id_model_mat INTEGER PRIMARY KEY AUTOINCREMENT, marque_mat TEXT NOT NULL, model_mat TEXT NOT NULL, id_typ_mat INTEGER, archiv TEXT DEFAULT 'N', dat_cre DATETIME DEFAULT CURRENT_TIMESTAMP)''',
      '''CREATE TABLE lieu_rep (id_lieu_rep INTEGER PRIMARY KEY AUTOINCREMENT, nom_lieu_rep TEXT NOT NULL, adr_lieu_rep TEXT, tel_lieu_rep TEXT, contact_rep TEXT, categorie_lieu TEXT DEFAULT 'EXTERIEUR', archiv TEXT DEFAULT 'N', dat_cre DATETIME DEFAULT CURRENT_TIMESTAMP)''',
      '''CREATE TABLE utilisateurs (id_uti INTEGER PRIMARY KEY AUTOINCREMENT, nom_uti TEXT NOT NULL, pnom_uti TEXT NOT NULL, mail_uti TEXT, id_str_mere INTEGER, archiv TEXT DEFAULT 'N', dat_cre DATETIME DEFAULT CURRENT_TIMESTAMP)''',
      '''CREATE TABLE materiel (id_mat INTEGER PRIMARY KEY AUTOINCREMENT, id_str INTEGER, id_typ_mat INTEGER, id_model_mat INTEGER, marque_mat TEXT, num_inv TEXT UNIQUE NOT NULL, num_ser TEXT NOT NULL DEFAULT '', dat_acq DATE, dat_mes DATE, etat_mat TEXT DEFAULT 'OP', obs_mat TEXT, ram INTEGER, disk INTEGER, cpu TEXT, se TEXT, net TEXT, ordi TEXT, ip TEXT, id_uti INTEGER, image_url TEXT, valeur_acq REAL DEFAULT 0, archiv TEXT DEFAULT 'N', dat_cre DATETIME DEFAULT CURRENT_TIMESTAMP, statut_mat TEXT DEFAULT 'ES', etat_reforme TEXT DEFAULT 'AUCUNE', motif_reforme TEXT, dat_mod DATETIME DEFAULT CURRENT_TIMESTAMP, annee_reforme INTEGER, lot_reforme TEXT, dat_sortie DATE, motif_sortie TEXT)''',
      '''CREATE TABLE affect_mat (id_aff_mat INTEGER PRIMARY KEY AUTOINCREMENT, id_mat INTEGER NOT NULL, id_str INTEGER, id_model_mat INTEGER, id_typ_mat INTEGER, num_inv TEXT, num_ser TEXT, dat_aff DATETIME DEFAULT CURRENT_TIMESTAMP, obs_aff TEXT, id_uti INTEGER, action_aff TEXT DEFAULT 'NOUVELLE_AFFECTATION', ancien_id_str INTEGER, ancien_id_uti INTEGER, archiv TEXT DEFAULT 'N', dat_cre DATETIME DEFAULT CURRENT_TIMESTAMP, dat_mod DATETIME DEFAULT CURRENT_TIMESTAMP)''',
      '''CREATE TABLE panne (id_pan INTEGER PRIMARY KEY AUTOINCREMENT, id_mat INTEGER NOT NULL, id_str INTEGER, id_typ_mat INTEGER, id_model_mat INTEGER, num_inv TEXT, num_ser TEXT, dat_pan DATE NOT NULL, diag_pan TEXT NOT NULL, dat_env_rep DATE, dat_ret_rep DATE, id_lieu_rep INTEGER, obs_rep TEXT, eta_pan TEXT DEFAULT 'EP', tp TEXT DEFAULT 'MAT', technicien TEXT, pieces_remplacees TEXT, recommandations TEXT, cout_rep REAL DEFAULT 0, archiv TEXT DEFAULT 'N', dat_cre DATETIME DEFAULT CURRENT_TIMESTAMP)''',
      '''CREATE TABLE historique_reforme (id_his_ref INTEGER PRIMARY KEY AUTOINCREMENT, id_mat INTEGER NOT NULL, etat_reforme TEXT NOT NULL, date_evenement DATE NOT NULL, motif_reforme TEXT, ancien_etat_reforme TEXT, dat_cre DATETIME DEFAULT CURRENT_TIMESTAMP)''',
      '''CREATE TABLE parametres_materiel (id_param INTEGER PRIMARY KEY AUTOINCREMENT, categorie TEXT NOT NULL, valeur TEXT NOT NULL, description TEXT, ordre INTEGER DEFAULT 0, archiv TEXT DEFAULT 'N')''',
      '''CREATE TABLE parametre_type_mat (id_param_type INTEGER PRIMARY KEY AUTOINCREMENT, id_typ_mat INTEGER NOT NULL, code_param TEXT NOT NULL, libelle_param TEXT NOT NULL, categorie_groupe TEXT, type_champ TEXT DEFAULT 'text', unite TEXT, options_predefinies TEXT, description TEXT, ordre INTEGER DEFAULT 0, archiv TEXT DEFAULT 'N', dat_cre DATETIME DEFAULT CURRENT_TIMESTAMP, dat_mod DATETIME DEFAULT CURRENT_TIMESTAMP)''',
    ];
    for (final sql in statements) { await db.execute(sql); }
    await db.execute('CREATE INDEX idx_materiel_num_ser ON materiel(num_ser)');
    await db.execute('CREATE INDEX idx_materiel_statut ON materiel(statut_mat, etat_mat)');
    await db.execute('CREATE INDEX idx_panne_materiel ON panne(id_mat, eta_pan)');
  }

  Future<int> count(String table, {String? where, List<Object?> args = const []}) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM $table ${where == null ? '' : 'WHERE $where'}', args);
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<List<Map<String, Object?>>> searchEquipment(String query) async {
    final q = '%${query.trim()}%';
    return db.rawQuery('''SELECT m.*, s.lib_str, u.nom_uti, u.pnom_uti, t.lib_typ_mat
      FROM materiel m LEFT JOIN structures s ON s.id_str=m.id_str
      LEFT JOIN utilisateurs u ON u.id_uti=m.id_uti
      LEFT JOIN type_mat t ON t.id_typ_mat=m.id_typ_mat
      WHERE COALESCE(m.archiv,'N') <> 'O' AND (m.num_inv LIKE ? OR m.num_ser LIKE ? OR m.marque_mat LIKE ? OR m.cpu LIKE ? OR m.se LIKE ?)
      ORDER BY m.num_inv''', [q,q,q,q,q]);
  }

  Future<List<Map<String, Object?>>> listEquipment({String filter = 'all'}) async {
    String clause = "COALESCE(m.archiv,'N') <> 'O'";
    if (filter == 'active') clause += " AND COALESCE(m.statut_mat,'ES') = 'ES'";
    if (filter == 'reform') clause += " AND COALESCE(m.statut_mat,'ES') = 'RF'";
    if (filter == 'proposed') clause += " AND COALESCE(m.statut_mat,'ES') = 'PR'";
    return db.rawQuery('''SELECT m.*, s.lib_str, u.nom_uti, u.pnom_uti, t.lib_typ_mat
      FROM materiel m LEFT JOIN structures s ON s.id_str=m.id_str
      LEFT JOIN utilisateurs u ON u.id_uti=m.id_uti
      LEFT JOIN type_mat t ON t.id_typ_mat=m.id_typ_mat
      WHERE $clause ORDER BY m.num_inv''');
  }

  Future<Map<String, Object?>> dashboard() async {
    final total = await count('materiel', where: "COALESCE(archiv,'N') <> 'O'");
    final active = await count('materiel', where: "COALESCE(archiv,'N') <> 'O' AND COALESCE(statut_mat,'ES')='ES'");
    final faults = await count('panne', where: "COALESCE(archiv,'N') <> 'O' AND COALESCE(eta_pan,'EP') IN ('EP','ER')");
    final proposed = await count('materiel', where: "COALESCE(statut_mat,'ES')='PR'");
    final reformed = await count('materiel', where: "COALESCE(statut_mat,'ES')='RF'");
    return {'total':total,'active':active,'faults':faults,'proposed':proposed,'reformed':reformed};
  }

  Future<String?> importDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite', 'sqlite3'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final selected = result.files.single;
    final docs = await getApplicationDocumentsDirectory();
    final target = p.join(docs.path, 'gparc.db');
    final temporary = p.join(docs.path, 'gparc-import-${DateTime.now().millisecondsSinceEpoch}.db');
    final backup = p.join(docs.path, 'gparc-backup-${DateTime.now().millisecondsSinceEpoch}.db');

    try {
      if (selected.path != null) {
        await File(selected.path!).copy(temporary);
      } else if (selected.bytes != null) {
        await File(temporary).writeAsBytes(selected.bytes!, flush: true);
      } else {
        throw Exception('Le fichier sélectionné est inaccessible.');
      }

      // Contrôle d'intégrité et de compatibilité avant de toucher à la base active.
      final candidate = await openDatabase(temporary, readOnly: true);
      try {
        final integrity = await candidate.rawQuery('PRAGMA integrity_check');
        if (integrity.isEmpty || integrity.first.values.first != 'ok') {
          throw Exception('Le fichier SQLite est endommagé.');
        }
        final tables = await candidate.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='materiel'",
        );
        if (tables.isEmpty) {
          throw Exception('Cette base ne contient pas la table materiel de GParc.');
        }
        final columns = await candidate.rawQuery('PRAGMA table_info(materiel)');
        final names = columns.map((row) => row['name']).toSet();
        if (!names.contains('num_inv') || !names.contains('num_ser') || !names.contains('id_mat')) {
          throw Exception('La structure de la table materiel est incompatible.');
        }
      } finally {
        await candidate.close();
      }

      await _db?.close();
      _db = null;
      if (await File(target).exists()) {
        await File(target).copy(backup);
        await File(target).delete();
      }
      await File(temporary).rename(target);
      _db = await openDatabase(
        target,
        version: 1,
        onConfigure: (database) async => database.execute('PRAGMA foreign_keys = ON'),
      );
      return target;
    } catch (_) {
      if (await File(temporary).exists()) await File(temporary).delete();
      if (_db == null) {
        if (!await File(target).exists() && await File(backup).exists()) {
          await File(backup).copy(target);
        }
        if (await File(target).exists()) {
          _db = await openDatabase(
            target,
            version: 1,
            onConfigure: (database) async => database.execute('PRAGMA foreign_keys = ON'),
          );
        }
      }
      rethrow;
    }
  }

  Future<String> databasePath() async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'gparc.db');
  }
}
