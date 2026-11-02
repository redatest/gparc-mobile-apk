import 'package:flutter/material.dart';

/// Associe les libellés de la table type_mat à une icône Material adaptée.
class EquipmentTypeIcon {
  EquipmentTypeIcon._();

  static IconData forType(Object? rawType) {
    final type = _normalize('${rawType ?? ''}');
    if (type.isEmpty) return Icons.devices_other;

    if (_has(type, ['portable', 'laptop', 'notebook', 'pc mobile'])) {
      return Icons.laptop;
    }
    if (_has(type, ['unite centrale', 'ordinateur', 'micro ordinateur', 'pc', 'workstation'])) {
      return Icons.computer;
    }
    if (_has(type, ['ecran', 'moniteur', 'monitor', 'display'])) {
      return Icons.monitor;
    }
    if (_has(type, ['imprimante', 'printer', 'photocopieur', 'photocopie', 'copieur', 'fax'])) {
      return Icons.print;
    }
    if (_has(type, ['scanner', 'numeriseur'])) {
      return Icons.document_scanner;
    }
    if (_has(type, ['serveur', 'server'])) {
      return Icons.dns;
    }
    if (_has(type, ['switch', 'commutateur', 'hub'])) {
      return Icons.hub;
    }
    if (_has(type, ['routeur', 'router'])) {
      return Icons.router;
    }
    if (_has(type, ['modem', 'point acces', 'access point', 'wifi'])) {
      return Icons.wifi;
    }
    if (_has(type, ['telephone', 'smartphone', 'mobile'])) {
      return Icons.smartphone;
    }
    if (_has(type, ['tablette', 'tablet'])) {
      return Icons.tablet_android;
    }
    if (_has(type, ['onduleur', 'ups', 'stabilisateur'])) {
      return Icons.battery_charging_full;
    }
    if (_has(type, ['clavier', 'keyboard'])) {
      return Icons.keyboard;
    }
    if (_has(type, ['souris', 'mouse'])) {
      return Icons.mouse;
    }
    if (_has(type, ['videoprojecteur', 'projecteur', 'video projecteur'])) {
      return Icons.slideshow;
    }
    if (_has(type, ['camera', 'webcam', 'video surveillance'])) {
      return Icons.camera_alt;
    }
    if (_has(type, ['disque dur', 'stockage', 'nas', 'baie'])) {
      return Icons.storage;
    }
    if (_has(type, ['haut parleur', 'enceinte', 'speaker', 'casque'])) {
      return Icons.headphones;
    }
    return Icons.devices_other;
  }

  static bool _has(String value, List<String> keywords) =>
      keywords.any(value.contains);

  static String _normalize(String value) {
    return value.toLowerCase().trim()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
