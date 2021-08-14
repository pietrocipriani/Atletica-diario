import 'dart:async';

import 'package:atletica/persistence/user_helper/snapshots_managers/schedule_snapshot.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/persistence/user_helper/snapshots_managers/result_snapshot.dart';
import 'package:atletica/persistence/user_helper/snapshots_managers/training_snapshot.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AthleteHelper extends FirebaseUserHelper {
  static final List<Callback> onCoachChanged = <Callback>[];

  void coachCallAll() =>
      onCoachChanged.forEach((c) => c.call(null, Change.UPDATED));

  DocumentReference? _athleteCoachReference;
  StreamSubscription<DocumentSnapshot>? _requestSubscription;
  DocumentReference? get coach {
    final DocumentReference? doc = athleteCoachReference?.parent.parent;
    assert(doc == null || RegExp(r'^users/[A-Za-z0-9]+$').hasMatch(doc.path));
    return doc;
  }

  DocumentReference? get athleteCoachReference => _athleteCoachReference;

  bool justRequested = false;
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
          accepted = last!['nickname'] != null && last!['group'] != null;
          coachCallAll();
        }
      },
    ).listen((snap) => last = snap);
    justRequested = false;
  }

  StreamSubscription<QuerySnapshot>? _schedulesSubscription;
  StreamSubscription<QuerySnapshot>? _trainingsSubscription;

  bool _accepted = false;
  bool get accepted => _accepted;
  set accepted(bool accepted) {
    if (_accepted == accepted) return;
    _accepted = accepted;
    if (accepted) {
      _schedulesSubscription =
          coach!.collection('schedules').snapshots().listen((snap) async {
        for (DocumentChange doc in snap.docChanges)
          await scheduleSnapshot(doc.doc, doc.type);
      });
      _trainingsSubscription =
          coach!.collection('trainings').snapshots().listen((snap) async {
        for (DocumentChange doc in snap.docChanges)
          await trainingSnapshot(doc.doc, doc.type);
      });
    } else {
      _schedulesSubscription?.cancel();
      _trainingsSubscription?.cancel();
      ScheduledTraining.cacheReset();
    }
  }

  bool get hasCoach => accepted;
  bool get hasRequest => athleteCoachReference != null && !accepted;
  bool get needsRequest => athleteCoachReference == null;

  AthleteHelper({
    required User user,
    required DocumentReference userReference,
    bool admin = false,
  }) : super(user: user, userReference: userReference, admin: admin) {
    _init();
  }

  void _init() {
    userReference.snapshots().listen((snap) async {
      print('received update: ${snap.data}');
      athleteCoachReference = snap['coach'] == null
          ? null
          : firestore
              .collection('users')
              .doc(snap['coach'])
              .collection('athletes')
              .doc(userReference.id);
      final DocumentSnapshot? athleteCoachSnapshot =
          await athleteCoachReference?.get();
      accepted = athleteCoachSnapshot?.data != null &&
          athleteCoachSnapshot!['nickname'] != null &&
          athleteCoachSnapshot['group'] != null;
      coachCallAll();
    });

    userReference.collection('results').snapshots().listen((snap) {
      for (DocumentChange change in snap.docChanges)
        resultSnapshot(change.doc, change.type);
    });
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
      'results':
          results.asIterable.map((e) => '${e.key.name}:${e.value}').toList(),
      'fatigue': results.fatigue,
      'info': results.info,
    }, SetOptions(merge: true));
  }

  Future<void>? deleteCoachSubscription() => athleteCoachReference?.delete();
}
