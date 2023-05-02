import 'dart:async';

import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/user_helper.dart';
import 'package:atletica/refactoring/common/src/model/role.dart';
import 'package:atletica/results/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachHelper extends UserHelper {
  Future<bool> listener(
    QuerySnapshot snap,
    Future<bool> Function(DocumentSnapshot docSnap, DocumentChangeType type) parse,
  ) async {
    bool modified = false;
    for (DocumentChange doc in snap.docChanges) if (await parse(doc.doc, doc.type)) modified = true;
    return modified;
  }

  bool showAsAthlete;
  bool showVariants;
  bool fictionalAthletes;

  CoachHelper.parse(final DocumentSnapshot<Map<String, Object?>> raw)
      : showAsAthlete = raw.getNullable('showAsAthlete') as bool? ?? false,
        showVariants = false,
        fictionalAthletes = raw.getNullable('fictionalAthletes') as bool? ?? true,
        super.parseGenerative(raw);

  CoachHelper({
    required super.user,
    required super.userReference,
    required this.showAsAthlete,
    required this.showVariants,
    required this.fictionalAthletes,
    required super.initialThemeMode,
    super.admin,
    super.category,
  }) {
    /* firestore.collection('global').doc('templates').get().then((snapshot) => addGlobalTemplates(snapshot));
    userReference.collection('templates').snapshots().listen((snap) => listener(snap, templateSnapshot));
    userReference.collection('athletes').snapshots().listen((snap) => listener(snap, athleteSnapshot));
    userReference.collection('trainings').snapshots().listen((snap) => listener(snap, trainingSnapshot));
    userReference.collection('plans').snapshots().listen((snap) => listener(snap, planSnapshot));
    userReference.collection('schedules').snapshots().listen((snap) => listener(snap, scheduleSnapshot)); */
  }

  /// `athleteUser` is the reference to [users/uid]
  /// `name` is the nickname displayed
  Future<void> addAthlete(
    DocumentReference? athlete,
    String nickname,
    String group,
  ) {
    return userReference.collection('athletes').doc(athlete?.id).set({'nickname': nickname, 'group': group});
  }

  Future<void> acceptRequest(
    DocumentReference request,
    String nickname,
    String group,
  ) async {
    await refuseRequest(request);
    await request.update({'nickname': nickname, 'group': group});
  }

  Future<void> refuseRequest(DocumentReference request) => request.delete();

  /// `athlete` is the reference to /coaches/$coach/athletes/$athlete
  Future<void> saveResult({
    required Athlete athlete,
    required Result results,
  }) {
    return athlete.resultsDoc.collection('results').doc(results.reference?.id).set({
      'date': Timestamp.fromDate(results.date),
      'coach': uid,
      'training': results.training,
      'results': results.asIterable.map((e) => '${e.key.name}:${e.value?.asLegacy}').toList(),
      'fatigue': results.fatigue,
      'info': results.info,
      // TODO: select target category
    }, SetOptions(merge: true));
  }

  @override
  bool get isAthlete => false;

  @override
  bool get isCoach => true;

  @override
  Future<H> setRole<H extends UserHelper>(final Role<H> role) async {
    if (role == Role.coach) return this as H;
    return super.setRole(role);
  }

  @override
  Map<String, Object?> get toMap => {
        ...super.toMap,
        ...{
          'showAsAthlete': showAsAthlete,
          'fictionalsAthlete': fictionalAthletes,
        },
      };
}
