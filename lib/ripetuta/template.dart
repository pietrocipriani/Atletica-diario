import 'dart:collection';

import 'package:atletica/persistence/auth.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final SplayTreeMap<String, SimpleTemplate> templates = SplayTreeMap<String, SimpleTemplate>();

class SimpleTemplate {
  final String name;
  Tipologia tipologia;
  final Target lastTarget;

  /* String? formattedTarget(final double? lastTarget) {
    if (lastTarget == null) return null;
    return '${tipologia.targetFormatter(lastTarget)} ${tipologia.targetSuffix ?? ''}';
  } */

  Future<void> create() {
    return Globals.coach.userReference.collection('templates').doc(name).set({
      'lastTarget': lastTarget.asMap,
      'tipologia': tipologia.name,
    });
  }

  SimpleTemplate({
    required this.name,
    required this.tipologia,
    final Target? lastTarget,
    final bool save = false,
  }) : lastTarget = lastTarget ?? Target.empty() {
    if (save) {
      final SimpleTemplate? last = templates[name];
      if (last == null || this is Template) templates[name] = this;
    }
  }

  @override
  String toString() => name;
}

class Template extends SimpleTemplate {
  Template.parse(final DocumentSnapshot raw)
      : this(
          name: raw.id,
          lastTarget: Target.parse(raw['lastTarget']),
          tipologia: Tipologia.parse(raw.getNullable('tipologia') as String?),
        );

  Template({required super.name, required super.lastTarget, required super.tipologia}) : super(save: true);

  Future<void> update() {
    return Globals.coach.userReference.collection('templates').doc(name).update({
      'lastTarget': lastTarget.asMap,
      'tipologia': tipologia.name,
    });
  }
}
