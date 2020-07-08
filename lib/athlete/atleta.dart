import 'dart:async';

import 'package:Atletica/athlete/athlete_dialog.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Athlete {
  /// `reference` is the reference for [coaches/$coachUid/athletes/$id]
  final DocumentReference reference;
  final String realName;
  String name, _group;
  String get group => _group;
  set group(String group) => lastGroup = (_group = group) ?? lastGroup;
  List<Allenamento> allenamenti = <Allenamento>[];

  bool get isRequest => name == null || group == null;
  bool get isAthlete => name != null && group != null;

  bool dismissed = false;

  /// `raw` is the snapshot for [coaches/$coachUid/athletes/$id]
  /// `user` is the snapshot for [coaches/$coachUid/athletes/$id/athlete -> /user]
  Athlete.parse({DocumentSnapshot raw, DocumentSnapshot user})
      : reference = raw.reference,
        realName = user['name'] {
    name = raw['nickname'];
    group = raw['group'];
  }

  static Future<bool> fromDialog(
      {@required BuildContext context, Athlete request}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => dialog(context: context, atleta: request),
    );
  }

  //static Future<void> create({})

  Future<void> update({@required String nickname, @required String group}) =>
      reference.updateData({'nickname': nickname, 'group': group});

  /// deleted `this` Athlete from `firestore`.
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
}
