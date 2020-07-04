import 'dart:async';

import 'package:Atletica/athlete/athlete_dialog.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/firestore.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Atleta {
  /// `reference` is the reference for [coaches/coachUid/athletes/uid]
  final DocumentReference reference;
  final String uid;
  String name;
  List<Allenamento> allenamenti = <Allenamento>[];

  bool dismissed = false;

  Atleta.parse(DocumentSnapshot raw)
      : reference = raw.reference,
        uid = raw.documentID {
    name = raw['nickname'];
    Group g = groups.firstWhere(
      (group) => group.name == raw['group'],
      orElse: () => null,
    );
    if (g == null) groups.add(g = Group(name: raw['group']));
    g.atleti.add(this);
    lastGroup = g;
  }
  static Atleta find(String uid) {
    for (Group g in groups)
      for (Atleta a in g.atleti) if (a.uid == uid) return a;
    return null;
  }

  static Future<bool> fromDialog(
      {@required BuildContext context, BasicUser user}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => dialog(context: context, user: user),
    );
  }

  static Future<void> create({
    @required DocumentReference request,
    @required String nickname,
    @required String group,
  }) async {
    return request.updateData({'nickname': nickname, 'group': group});
  }

  Future<void> update({@required String nickname, @required String group}) =>
      reference.updateData({'nickname': nickname, 'group': group});

  /// deleted `this` Atleta from `firestore`.
  Future<void> delete() {
    dismissed = true;
    return reference.delete();
  }

  Future<bool> modify({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => dialog(context: context, atleta: this),
    );
  }

  void localMigration(String groupName) {
    final Group current = groups.firstWhere(
      (group) => group.atleti.contains(this),
    );
    if (groupName == null) {
      if (current == null) return;
      current.atleti.remove(this);
      if (current.atleti.isEmpty) groups.remove(current);
      return;
    }
    Group newGroup = groups.firstWhere(
      (group) => group.name == groupName,
      orElse: () => null,
    );
    if (newGroup == null) groups.add(newGroup = Group(name: groupName));
    if (current == newGroup) return;
    if (current != null) {
      current.atleti.remove(this);
      if (current.atleti.isEmpty) groups.remove(current);
    }
    newGroup.atleti.add(this);
  }
}
