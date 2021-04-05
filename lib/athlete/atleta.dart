import 'dart:async';
import 'dart:math';

import 'package:atletica/athlete/athlete_dialog.dart';
import 'package:atletica/athlete/group.dart';
import 'package:atletica/persistence/auth.dart' as auth;
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/results/simple_training.dart';
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

  int get trainingsCount => results.values.where((r) => !r.isBooking).length;
  StreamSubscription _trainingsCountSubscription;
  final Map<String, Result> results = {};

  /// `tbs`: training bests
  ///
  /// the key of the Map is the `':'` concatenation of the `Result.ripetute` iterable
  ///
  /// the key of the inner Map is `SimpleRipetuta.name`
  /// and the value is the corrispective double value to format
  final Map<String, Map<String, double>> tbs = {};
  final Map<String, double> pbs = {};

  double tb(String identifier, String rip) {
    dynamic a = tbs[identifier] ?? {};
    return a[rip];
  }

  double pb(String rip) => pbs[rip];

  void _reloadPbsTbs() {
    for (String key in results.keys) {
      if (key == null) continue;
      _updatePbsTbs(key);
    }
  }

  void _updatePbsTbs(String added) {
    final Result result = results[added];
    if (result == null) return;
    final String identifier = result.uniqueIdentifier;
    for (final MapEntry<SimpleRipetuta, double> e in result.asIterable) {
      if (e.value == null) continue;
      pbs[e.key.name] = min(e.value, pbs[e.key.name] ?? double.infinity);
      final Map<String, double> map = tbs[identifier] ??= <String, double>{};
      map[e.key.name] = min(
        e.value,
        map[e.key.name] ?? double.infinity,
      );
    }
  }

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
      print(cast.documentChanges);
      for (DocumentChange change in cast.documentChanges) {
        print(change.type);
        if (change.type == DocumentChangeType.removed)
          results.remove(change.document.documentID);
        else
          results[change.document.documentID] = Result(change.document);

        if (change.type == DocumentChangeType.added)
          _updatePbsTbs(change.document.documentID);
        else
          _reloadPbsTbs();
      }
      print(results);
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

  @override
  String toString() => name;
}
