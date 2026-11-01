# Gparc Mobile

Application Android native Flutter/Dart de gestion du parc informatique, conçue pour fonctionner **entièrement hors ligne**.

## Télécharger l'application

**[Télécharger l'APK Android (version Debug)](https://github.com/redatest/gparc-mobile-apk/actions/runs/41351970376/artifacts/13102010385)**

- Build GitHub Actions : [consulter les résultats](https://github.com/redatest/gparc-mobile-apk/actions/runs/41351970376).
- Analyse Flutter, tests et compilation : réussis.
- Type : APK Debug, destiné aux essais.
- L'artefact GitHub est conservé pendant **30 jours** après sa génération. Le lien direct expirera donc avec l'artefact.
- Pour les builds ultérieurs : ouvrir l'onglet [Actions](https://github.com/redatest/gparc-mobile-apk/actions/workflows/android.yml), sélectionner le dernier workflow réussi, puis télécharger `gparc-mobile-debug` dans la section **Artifacts**.

> L'APK a été compilé avec succès par CI. Son fonctionnement doit encore être validé sur des appareils Android réels avant toute diffusion en production.

## Principes

- Flutter et Dart pour toute l'application ; aucune WebView.
- Hôte Android minimal généré en Java par Flutter (aucune logique métier native Kotlin).
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
flutter create --platforms=android --android-language java --org dz.sonelgaz --project-name gparc_mobile .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Compilation automatisée

Le workflow GitHub Actions compile l'APK Android de debug à chaque push sur `main` et lors d'un déclenchement manuel.

## État du projet

Portage en cours. La compilation CI est validée ; les fonctionnalités et la compatibilité doivent encore être vérifiées sur appareils Android réels.
