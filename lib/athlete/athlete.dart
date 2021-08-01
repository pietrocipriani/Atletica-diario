import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:atletica/athlete/athlete_dialog.dart';
import 'package:atletica/athlete/group.dart';
import 'package:atletica/cache.dart';
import 'package:atletica/persistence/auth.dart' as auth;
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/results/simple_training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Athlete {
  static final Cache<DocumentReference, Athlete> _cache = Cache();
  static final SplayTreeSet<Athlete> sortedFullAthletes = SplayTreeSet((a, b) {
    int compare = 0;
    if (a.group != null) compare += a.group!.compareTo(b.group ?? '') * 2;
    compare += a.name.compareTo(b.name);
    return compare;
  });

  static Iterable<Athlete> get fullAthletes => sortedFullAthletes;
  static Iterable<Athlete> getFullAthletes(
      final Iterable<DocumentReference> refs) {
    return refs.map<Athlete?>((r) => _cache[r]).whereType<Athlete>();
  }

  static Iterable<Athlete> get requests =>
      fullAthletes.where((a) => a.isRequest);
  static bool get hasRequests => fullAthletes.any((a) => a.isRequest);
  static Iterable<Athlete> getRequests(final Iterable<DocumentReference> refs) {
    return getFullAthletes(refs).where((a) => a.isRequest);
  }

  static Iterable<Athlete> get athletes =>
      fullAthletes.where((a) => a.isAthlete);
  static bool get hasAthletes => fullAthletes.any((a) => a.isAthlete);
  static Iterable<Athlete> getAthletes(
      final Iterable<DocumentReference>? refs) {
    if (refs == null) return Iterable.empty();
    return getFullAthletes(refs).where((a) => a.isAthlete);
  }

  static void Function() cacheReset = _cache.reset;

  static void Function(auth.Callback c) signIn = _cache.signIn;
  static void Function(auth.Callback c) signOut = _cache.signOut;

  static bool exists(final DocumentReference ref) => _cache.contains(ref);

  static bool isNameInUse(final String name) =>
      athletes.any((t) => t.name == name);

  /// `reference` is the reference for [coaches/$coachUid/athletes/$id]
  final String? uid;
  final DocumentReference? athlete;
  final DocumentReference reference;
  DocumentReference get resultsDoc => athlete ?? reference;

  String name;
  late String? _group;
  String? get group => _group;
  set group(String? group) => lastGroup = (_group = group) ?? lastGroup;

  int get trainingsCount => results.values.where((r) => !r.isBooking).length;
  late StreamSubscription _trainingsCountSubscription;
  final Map<String, Result> results = {};

  /// `tbs`: training bests
  ///
  /// the key of the Map is the `':'` concatenation of the `Result.ripetute` iterable
  ///
  /// the key of the inner Map is `SimpleRipetuta.name`
  /// and the value is the corrispective double value to format
  final Map<String, Map<String, double>> tbs = {};
  final Map<String, double> pbs = {};

  double? tb(String identifier, String rip) {
    final Map<String, double> a = tbs[identifier] ?? {};
    return a[rip];
  }

  double? pb(String rip) => pbs[rip];

  void _reloadPbsTbs() {
    for (String key in results.keys) {
      if (key == null) continue;
      _updatePbsTbs(key);
    }
  }

  void _updatePbsTbs(String added) {
    final Result? result = results[added];
    if (result == null) return;
    final String identifier = result.uniqueIdentifier;
    for (final MapEntry<SimpleRipetuta, double?> e in result.asIterable) {
      if (e.value == null) continue;
      pbs[e.key.name] = min(e.value!, pbs[e.key.name] ?? double.infinity);
      final Map<String, double> map = tbs[identifier] ??= <String, double>{};
      map[e.key.name] = min(
        e.value!,
        map[e.key.name] ?? double.infinity,
      );
    }
  }

  bool get isRequest => group == null;
  bool get isAthlete => group != null;

  bool dismissed = false;

  factory Athlete.of(final DocumentReference ref) {
    final Athlete? a = _cache[ref];
    if (a == null) throw StateError('cannot find Athlete of ${ref.path}');
    return a;
  }
  static Athlete? tryOf(final DocumentReference? ref) {
    if (ref == null) return null;
    try {
      return Athlete.of(ref);
    } on StateError {
      return null;
    }
  }

  factory Athlete.parse(final DocumentSnapshot raw, final bool exists) {
    final Athlete p = _cache[raw.reference] ??= Athlete._parse(raw, exists);
    _cache.notifyAll(p);
    return p;
  }

  /// `reference` is the reference to [users/$coachUid/athletes/$uid]
  /// `athlete` is the reference to [users/$uid]
  Athlete._parse(DocumentSnapshot raw, bool exists)
      : reference = raw.reference,
        uid = exists ? raw.id : null,
        name = raw['nickname'],
        athlete = exists ? firestore.collection('users').doc(raw.id) : null {
    group = raw['group'];
    _trainingsCountSubscription =
        auth.userC.resultSnapshots(athlete: this).listen((e) {
      if (e == null) return;
      final QuerySnapshot cast = e;
      for (DocumentChange change in cast.docChanges) {
        if (change.type == DocumentChangeType.removed)
          results.remove(change.doc.id);
        else
          results[change.doc.id] = Result(change.doc);

        if (change.type == DocumentChangeType.added)
          _updatePbsTbs(change.doc.id);
        else
          _reloadPbsTbs();
      }
    });
    sortedFullAthletes.add(this);
  }
  factory Athlete.update(final DocumentSnapshot raw) {
    final Athlete p = Athlete.of(raw.reference);
    sortedFullAthletes.remove(p);
    p.name = raw['nickname'];
    p.group = raw['group'];
    sortedFullAthletes.add(p);
    //TODO: update _trainingsCountSubscription
    _cache.notifyAll(p);
    return p;
  }

  static void remove(final DocumentReference ref) {
    final Athlete? p = _cache.remove(ref);
    sortedFullAthletes.remove(p);
    if (p != null) _cache.notifyAll(p);
  }

  static Future<bool?> fromDialog(
      {required BuildContext context, Athlete? request}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => dialog(context: context, atleta: request),
    );
  }

  //static Future<void> create({})

  Future<void> update({required String nickname, required String group}) =>
      reference.update({'nickname': nickname, 'group': group});

  static Future<void> create({
    required String nickname,
    required String group,
  }) =>
      auth.userC.addAthlete(null, nickname, group);

  /// deleted `this` Athlete from `firestore`.
  Future<void> delete() {
    dismissed = true;
    _trainingsCountSubscription.cancel();
    return reference.delete();
  }

  Future<bool?> modify({required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => dialog(context: context, atleta: this),
    );
  }

  @override
  String toString() => name;
}
