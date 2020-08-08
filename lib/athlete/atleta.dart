import 'dart:async';

import 'package:Atletica/athlete/athlete_dialog.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/persistence/auth.dart' as auth;
import 'package:Atletica/persistence/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Athlete {
  /// `reference` is the reference for [coaches/$coachUid/athletes/$id]
  final String uid;
  final DocumentReference athlete;
  final DocumentReference reference;
  DocumentReference get resultsDoc => athlete ?? reference;

  String name, _group;
  String get group => _group;
  set group(String group) => lastGroup = (_group = group) ?? lastGroup;

  int trainingsCount = 0;
  StreamSubscription _trainingsCountSubscription;

  bool get isRequest => group == null;
  bool get isAthlete => group != null;

  bool dismissed = false;

  /// `reference` is the reference to [users/$coachUid/athletes/$uid]
  /// `athlete` is the reference to [users/$uid]
  Athlete.parse(DocumentSnapshot raw, bool exists)
      : reference = raw.reference,
        uid = exists ? raw.documentID : null,
        athlete = exists
            ? firestore.collection('users').document(raw.documentID)
            : null {
    name = raw['nickname'];
    group = raw['group'];
    _trainingsCountSubscription =
        auth.userC.resultSnapshots(athlete: this).listen((e) {
      if (e == null) return;
      final QuerySnapshot cast = e;
      trainingsCount = cast.documents
          .where((doc) => doc['results'].any((l) => !l.endsWith('null')))
          .length;
    });
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

  static Future<void> create({
    @required String nickname,
    @required String group,
  }) =>
      auth.userC.addAthlete(null, nickname, group);

  /// deleted `this` Athlete from `firestore`.
  Future<void> delete() {
    dismissed = true;
    _trainingsCountSubscription?.cancel();
    return reference.delete();
  }

  Future<bool> modify({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => dialog(context: context, atleta: this),
    );
  }
}
