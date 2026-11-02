# GParc Mobile

Application Android native Flutter/Dart de gestion du parc informatique, conçue pour fonctionner **entièrement hors ligne**.

## Télécharger l'application

**[Télécharger le dernier APK Android](https://github.com/redatest/gparc-mobile-apk/releases/download/latest/gparc-mobile.apk)**

Ce lien est permanent : le workflow GitHub Actions remplace automatiquement le fichier APK de cette version à chaque compilation réussie sur `main`. Le lien du README n'a donc pas besoin d'être modifié à chaque commit.

- [Consulter les compilations et les contrôles CI](https://github.com/redatest/gparc-mobile-apk/actions/workflows/android.yml).
- APK Debug, destiné aux essais.
- L'APK est publié uniquement si l'analyse Flutter, les tests et la compilation réussissent.

## Principes

- Flutter et Dart pour toute l'application ; aucune WebView.
- Hôte Android minimal généré en Java par Flutter.
- Base SQLite locale, importée depuis un fichier `.db` Gparc.
- Aucun serveur, Flask, Python, Oracle ou synchronisation réseau.
- Les données restent sur l'appareil.
- Le dépôt source Gparc n'est pas modifié.

## Fonctionnalités

- Consultation, recherche et filtrage du parc.
- Recherche par lecture de code-barres depuis l'accueil ou l'écran du parc.
- Fiche détaillée d'un équipement et gestion des informations.
- Utilisateurs, structures, types et modèles.
- Affectations et historique.
- Déclaration et suivi des pannes, réparations et réformes.
- Tableau de bord et statistiques.
- Import, export et sauvegarde de la base SQLite.

## Base de données

Le format de référence est le schéma SQLite de Gparc. L'application mobile ne déclenche aucune synchronisation Oracle. Les tables techniques propres à Oracle sont exclues du fonctionnement mobile.

L'import d'une base existante doit être réalisé depuis l'écran de gestion de la base. Conserver une copie de sauvegarde avant toute migration.

## Développement

Prérequis : Flutter stable avec Android SDK.

```bash
flutter create --platforms=android --android-language java --org dz.sonelgaz --project-name gparc_mobile .
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter build apk --debug
```

## Compilation automatisée

Le workflow GitHub Actions compile l'APK Android à chaque push sur `main` et lors d'un déclenchement manuel. Après validation, il publie l'APK sous le tag de release stable `latest` et conserve également l'artefact de compilation.

## État du projet

Portage en cours. La compilation CI est contrôlée automatiquement ; les fonctionnalités et la compatibilité doivent être vérifiées sur appareils Android réels.
