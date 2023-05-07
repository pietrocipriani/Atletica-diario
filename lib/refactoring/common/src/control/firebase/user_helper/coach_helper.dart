import 'dart:async';

import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/plan/plan.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/user_helper.dart';
import 'package:atletica/refactoring/common/src/model/utils/firestore_cache.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/refactoring/utils/cast.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachHelper extends UserHelper {
  static final Finalizer<FirestoreCache> _finalizer =
      Finalizer((subscription) => subscription.cancel());

  bool showAsAthlete;

  bool showVariants;
  bool fictionalAthletes;
  late final FirestoreCache<Athlete> athletes;

  late final FirestoreCache<Training> trainings;
  late final FirestoreCache<Plan> plans;
  late final FirestoreCache<ScheduledTraining> schedules;

  CoachHelper.parse(
    final DocumentSnapshot<Map<String, Object?>> raw,
  )   : showAsAthlete = cast<bool>(raw.getNullable('showAsAthlete'), false),
        showVariants = false,
        fictionalAthletes = cast<bool>(
          raw.getNullable('fictionalAthletes'),
          true,
        ),
        super.parse(raw) {
    init();
  }

  Future<void> acceptRequest(
    DocumentReference request,
    String nickname,
    String group,
  ) async {
    await refuseRequest(request);
    await request.update({'nickname': nickname, 'group': group});
  }

  /// `athleteUser` is the reference to [users/uid]
  /// `name` is the nickname displayed
  Future<void> addAthlete(
    DocumentReference? athlete,
    String nickname,
    String group,
  ) {
    return userReference
        .collection('athletes')
        .doc(athlete?.id)
        .set({'nickname': nickname, 'group': group});
  }

  void init() {
    // TODO: uniformate with others
    SimpleTemplate.loadGlobalsFromFirestore(this);

    athletes = FirestoreCache(
      collection: userReference.collection('athletes'),
      create: (snap) {
        // TODO: existence of users shouldn't be determined in this manner.
        // bool exists =
        //    (await firestore.collection('users').doc(snap.id).get()).exists;
        return Athlete.parse(snap, /*exists*/ true);
      },
      edit: Athlete.update,
      finalize: Athlete.remove,
    );
    trainings = FirestoreCache(
      collection: userReference.collection('trainings'),
      create: Training.parse,
      edit: Training.update,
      finalize: Training.remove,
    );
    plans = FirestoreCache(
      collection: userReference.collection('plans'),
      create: Plan.parse,
      edit: Plan.update,
      finalize: Plan.remove,
    );
    schedules = FirestoreCache(
      collection: userReference.collection('schedules'),
      create: ScheduledTraining.parse,
      edit: ScheduledTraining.updateStatic,
      finalize: ScheduledTraining.remove,
    );

    _finalizer.attach(this, athletes, detach: this);
    _finalizer.attach(this, trainings, detach: this);
    _finalizer.attach(this, plans, detach: this);
    _finalizer.attach(this, schedules, detach: this);
  }

  Future<bool> listener(
    QuerySnapshot snap,
    Future<bool> Function(DocumentSnapshot docSnap, DocumentChangeType type)
        parse,
  ) async {
    bool modified = false;
    for (DocumentChange doc in snap.docChanges) {
      if (await parse(doc.doc, doc.type)) modified = true;
    }
    return modified;
  }

  /*CollectionReference<Template> get templates =>
      userReference.collection('templates').withConverter<Template>(
            fromFirestore: (snap, _) => Template.parse(snap),
            toFirestore: (template, _) => template.toFirestore(),
          );*/

  void logout() {
    athletes.cancel();
    plans.cancel();
    schedules.cancel();
    trainings.cancel();
    _finalizer.detach(this);
  }

  Future<void> refuseRequest(DocumentReference request) => request.delete();

  /// `athlete` is the reference to /coaches/$coach/athletes/$athlete
  Future<void> saveResult({
    required Athlete athlete,
    required Result results,
  }) {
    return athlete.resultsDoc
        .collection('results')
        .doc(results.reference?.id)
        .set({
      'date': Timestamp.fromDate(results.date),
      'coach': uid,
      'training': results.training,
      'results': results.asIterable
          .map((e) => '${e.key.name}:${e.value?.asLegacy}')
          .toList(),
      'fatigue': results.fatigue,
      'info': results.info,
      // TODO: select target category
    }, SetOptions(merge: true));
  }

  @override
  Map<String, Object?> get asMap => {
        ...super.asMap,
        'showAsAthlete': showAsAthlete,
        'fictionalsAthlete': fictionalAthletes,
      };
}
