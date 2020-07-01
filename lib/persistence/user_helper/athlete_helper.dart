import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AthleteHelper extends FirebaseUserHelper {
  final DocumentReference athleteReference;
  dynamic _coach;
  String role;

  set coach(dynamic coach) {
    assert(coach == null || coach is BasicUser || coach is CoachRequest);
    //print (StackTrace.current);
    if (coach == _coach) return;
    if (_coach != null && _coach is CoachRequest) _coach.subscription?.cancel();
    _coach = coach;
  }

  get coach => _coach;

  AthleteHelper({
    @required FirebaseUser user,
    @required DocumentReference userReference,
  })  : athleteReference = firestore.collection('athletes').document(user.uid),
        super(user: user, userReference: userReference) {
    _init();
  }

  void _init() async {
    await _getCoach();
  }

  Future<bool> requestCoach({@required DocumentReference coach}) async {
    final DocumentReference request =
        firestore.collection('requests').document();
    if (coach == null || userReference == coach) return false;
    final WriteBatch batch = firestore.batch();
    if (this.coach != null) batch.delete(this.coach);

    batch.updateData(userReference, {'coach': request});
    await request.setData({'coach': coach, 'athlete': userReference});
    this.coach = CoachRequest(this, request);

    batch.commit();
    return true;
  }

  Future<void> _getCoach() async {
    DocumentReference coach = (await athleteReference.get()).data['coach'];
    if (coach == null || !(await coach.get()).exists) {
      this.coach = null;
      return;
    }

    if (coach.parent().id == 'requests') {
      this.coach = CoachRequest(this, coach);
      return;
    }
    this.coach = coach;
  }
}
