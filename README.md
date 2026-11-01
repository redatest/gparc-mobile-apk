# GParc Mobile

Application Android native Flutter/Dart de gestion du parc informatique, conçue pour fonctionner **entièrement hors ligne**.

## Principes

- Flutter et Dart ; aucune WebView.
- Base SQLite locale, importée depuis un fichier `.db` Gparc.
- Aucun serveur, Flask, Python, Oracle ou synchronisation réseau.
- Les données restent sur l'appareil.
- Le dépôt source Gparc n'est pas modifié.

## Fonctionnalités prévues

- Consultation, recherche et filtrage du parc.
- Fiche détaillée d'un équipement et gestion des informations.
- Utilisateurs, structures, types et modèles.
- Affectations et historique.
- Déclaration et suivi des pannes, réparations et réformes.
- Tableau de bord et statistiques.
- Lecture de codes-barres.
- Import, export et sauvegarde de la base SQLite.
- Impression / génération de fiches.

## Base de données

Le format de référence est le schéma SQLite de Gparc. L'application mobile ne déclenche aucune synchronisation Oracle. Les tables techniques propres à Oracle sont exclues du fonctionnement mobile.

L'import d'une base existante doit être réalisé depuis l'écran de gestion de la base. Conserver une copie de sauvegarde avant toute migration.

## Développement

Prérequis : Flutter stable avec Android SDK.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Compilation automatisée

Le workflow GitHub Actions compile l'APK Android de debug à chaque push sur `main` et permet de télécharger l'artefact depuis l'onglet Actions.

## État du projet

Portage en cours. Les versions APK ne seront annoncées comme testées qu'après compilation et vérification effectives par CI.
