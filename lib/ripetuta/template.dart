import 'dart:collection';

import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// The cache for the templates.
/// A template can be used as exercise name. It is a template for reps.
/// Reps add a target.
/// Templates are useful in keeping a consistent naming of exercises, obtained via autocompletion
final SplayTreeMap<String, SimpleTemplate> templates =
    SplayTreeMap<String, SimpleTemplate>();

class SimpleTemplate {
  final String name;
  Tipologia tipologia;
  final Target lastTarget;

  /* String? formattedTarget(final double? lastTarget) {
    if (lastTarget == null) return null;
    return '${tipologia.targetFormatter(lastTarget)} ${tipologia.targetSuffix ?? ''}';
  } */

  static Future<void> loadGlobalsFromFirestore(
    final CoachHelper helper,
  ) async {
    final doc = await firestore.collection('global').doc('templates').get();
    if (!doc.exists) return;

    final data = doc.getNullable('templates');
    if (data is! List || data.any((t) => t is! String)) return;

    for (final String template in data.cast()) {
      templates[template] = SimpleTemplate(
        name: template,
        tipologia: Tipologia.corsaDist,
      );
    }

    helper.templates.snapshots().listen((event) {
      for (final doc in event.docChanges) {
        switch (doc.type) {
          case DocumentChangeType.modified:
          case DocumentChangeType.added:
            doc.doc.data()?.putInCache();
            break;
          case DocumentChangeType.removed:
            templates.remove(doc.doc.id);
            break;
        }
      }
    });
  }

  bool putInCache() {
    final SimpleTemplate? last = templates[name];
    if (last == null || this is Template) {
      templates[name] = this;
      return true;
    }
    return false;
  }

  Future<void> create() {
    return Globals.helper.userReference.collection('templates').doc(name).set({
      'lastTarget': lastTarget.asMap,
      'tipologia': tipologia.name,
    });
  }

  SimpleTemplate({
    required this.name,
    required this.tipologia,
    final Target? lastTarget,
  }) : lastTarget = lastTarget ?? Target.empty();

  @override
  String toString() => name;
}

class Template extends SimpleTemplate {
  Template.parse(final DocumentSnapshot<Map<String, Object?>> raw)
      : this(
          name: raw.id,
          lastTarget: Target.parse(raw['lastTarget']),
          tipologia: Tipologia.parse(raw.getNullable('tipologia') as String?),
        );

  Template(
      {required super.name,
      required super.lastTarget,
      required super.tipologia});

  Future<void> update() {
    return Globals.helper.userReference
        .collection('templates')
        .doc(name)
        .update({
      'lastTarget': lastTarget.asMap,
      'tipologia': tipologia.name,
    });
  }

  Map<String, Object?> toFirestore() => {
        'lastTarget': lastTarget.asMap,
        'tipologia': tipologia.name,
      };
}
