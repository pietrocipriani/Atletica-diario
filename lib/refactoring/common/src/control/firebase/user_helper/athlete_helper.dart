import 'dart:async';

import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/model/utils/firestore_cache.dart';
import 'package:atletica/refactoring/utils/cast.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AthleteHelper extends UserHelper {
  static final List<Callback> onCoachChanged = <Callback>[];

  /// The results for this user as athlete. User property.
  late final FirestoreCache<Result> results;

  /// The schedules scheduled by the coach for this user as athlete. Coach property.
  FirestoreCache<ScheduledTraining>? schedules;

  /// The trainings prepared by the coach for this user as athlete. Coach property.
  FirestoreCache<Training>? trainings;

  DocumentReference? _athleteCoachReference;

  StreamSubscription<DocumentSnapshot>? _requestSubscription;
  bool justRequested = false;
  bool _accepted = false;

  static Future<AthleteHelper> parse(
    final DocumentSnapshot<Map<String, Object?>> raw,
  ) async {
    final String? coach = cast<String?>(raw.getNullable('coach'), null);
    final DocumentReference? athleteCoachReference = coach == null
        ? null
        : firestore
            .collection('users')
            .doc(coach)
            .collection('athletes')
            .doc(raw.id);

    final DocumentSnapshot? athleteCoachSnapshot =
        await athleteCoachReference?.get();
    final bool accepted = athleteCoachSnapshot?.data() != null &&
        athleteCoachSnapshot!.getNullable('nickname') != null &&
        athleteCoachSnapshot.getNullable('group') != null;

    return AthleteHelper._parse(raw, athleteCoachReference, accepted);
  }

  AthleteHelper._parse(
    final DocumentSnapshot<Map<String, Object?>> raw,
    final DocumentReference? coachReference,
    final bool accepted,
  ) : super.parse(raw) {
    //_initCoach(raw['coach']);
    this.athleteCoachReference = coachReference;
    this.accepted = accepted;
    _init();
  }

  bool get accepted => _accepted;

  set accepted(bool accepted) {
    if (_accepted == accepted) return;
    _accepted = accepted;
    if (accepted) {
      schedules?.cancel();
      trainings?.cancel();
      schedules = FirestoreCache(
        collection: coach!.collection('schedules'),
        create: ScheduledTraining.parse,
        edit: ScheduledTraining.updateStatic,
        finalize: ScheduledTraining.remove,
      );
      trainings = FirestoreCache(
        collection: coach!.collection('trainings'),
        create: Training.parse,
        edit: Training.update,
        finalize: Training.remove,
      );
    } else {
      schedules?.cancel();
      trainings?.cancel();
      ScheduledTraining.cacheReset();
    }
  }

  DocumentReference? get athleteCoachReference => _athleteCoachReference;
  set athleteCoachReference(DocumentReference? reference) {
    if (reference == _athleteCoachReference) return;
    _requestSubscription?.cancel();
    _athleteCoachReference = reference;
    DocumentSnapshot? last;
    _requestSubscription = reference?.snapshots().timeout(
      const Duration(milliseconds: 10),
      onTimeout: (sink) {
        if (last == null) return;
        if (!last!.exists)
          userReference.update({'coach': null});
        else {
          accepted = last!.getNullable('nickname') != null &&
              last!.getNullable('group') != null;
          coachCallAll();
        }
      },
    ).listen((snap) => last = snap);
    justRequested = false;
  }

  DocumentReference? get coach {
    final DocumentReference? doc = athleteCoachReference?.parent.parent;
    assert(doc == null || RegExp(r'^users/[A-Za-z0-9]+$').hasMatch(doc.path));
    return doc;
  }

  bool get hasCoach => accepted;
  bool get hasRequest => athleteCoachReference != null && !accepted;

  bool get needsRequest => athleteCoachReference == null;

  void coachCallAll() =>
      onCoachChanged.forEach((c) => c.call(null, Change.UPDATED));

  Future<void>? deleteCoachSubscription() => athleteCoachReference?.delete();

  void logout() {
    results.cancel();
    schedules?.cancel();
    trainings?.cancel();
  }

  Future<bool> requestCoach(
      {required String uid, required String nickname}) async {
    if (uid == userReference.id) return false;
    final DocumentReference request = firestore
        .collection('users')
        .doc(uid)
        .collection('athletes')
        .doc(userReference.id);
    if (athleteCoachReference == request) return false;
    final WriteBatch batch = firestore.batch();

    if (athleteCoachReference != null) batch.delete(athleteCoachReference!);
    batch.update(userReference, {'coach': uid});
    batch.set(request, {'nickname': nickname}, SetOptions(merge: true));
    justRequested = true;
    await batch.commit();

    return true;
  }

  Future<void> saveResult(Result results) {
    return (results.reference ?? userReference.collection('results').doc())
        .set({
      'date': Timestamp.fromDate(results.date),
      'coach': coach!.id,
      'training': results.training,
      'results': results.asIterable
          .map((e) => '${e.key.name}:${e.value?.asLegacy}')
          .toList(),
      'fatigue': results.fatigue,
      'info': results.info,
    }, SetOptions(merge: true));
  }

  void _init() {
    userReference.snapshots(includeMetadataChanges: true).listen((snap) {
      if (snap.metadata.hasPendingWrites) return;
      if (snap.metadata.isFromCache) return;
      _initCoach(cast<String?>(snap.getNullable('coach'), null));
    });

    results = FirestoreCache(
      collection: userReference.collection('results'),
      create: Result.parse,
      edit: Result.update,
      finalize: Result.remove,
    );
  }

  Future<void> _initCoach(final String? coach) async {
    athleteCoachReference = coach == null
        ? null
        : firestore
            .collection('users')
            .doc(coach)
            .collection('athletes')
            .doc(userReference.id);
    final DocumentSnapshot? athleteCoachSnapshot =
        await athleteCoachReference?.get();
    accepted = athleteCoachSnapshot?.data != null &&
        athleteCoachSnapshot!.getNullable('nickname') != null &&
        athleteCoachSnapshot.getNullable('group') != null;
    coachCallAll();
  }

  @override
  Map<String, Object?> get asMap => {
        ...super.asMap,
        'coach': coach?.id,
      };
}
