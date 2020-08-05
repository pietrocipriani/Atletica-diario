import 'dart:async';

import 'package:Atletica/date.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

DateTime bareDT([DateTime dt]) {
  dt ??= DateTime.now();
  dt = dt.toUtc();
  return DateTime.utc(dt.year, dt.month, dt.day);
}

DateTime nextStartOfWeek([DateTime dt]) {
  dt ??= DateTime.now();
  dt = bareDT(dt);
  if (dt.weekday == DateTime.monday) return dt;
  final int shift = 7 - (dt.weekday - DateTime.monday) % 7;
  return dt.add(Duration(days: shift));
}

class ScheduledTraining {
  final DocumentReference reference;
  final DocumentReference workRef;
  final Date date;
  final DocumentReference plan;

  ScheduledTraining.parse(DocumentSnapshot snap)
      : reference = snap.reference,
        workRef = snap['work'],
        date = Date.fromTimeStamp(snap['date']),
        plan = snap['plan'];

  ScheduledTraining._(this.reference, this.workRef, {DateTime date, this.plan})
      : this.date = Date.fromDateTime(date);

  Allenamento get work => allenamenti[workRef];

  static FutureOr<void> create(
      {@required DocumentReference work,
      @required DateTime date,
      Tabella plan,
      WriteBatch batch}) {
    if (batch == null)
      return userC.userReference
          .collection('schedules')
          .add({'work': work, 'date': date, 'plan': plan?.reference});
    batch.setData(userC.userReference.collection('schedules').document(),
        {'work': work, 'date': date, 'plan': plan.reference});
  }

  bool get isValid => date < Date.now(); // ?

  bool get isOk => workRef != null && date != null;
}
