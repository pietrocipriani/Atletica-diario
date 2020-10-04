import 'dart:async';

import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/group.dart';
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
  final List<DocumentReference> athletes;

  ScheduledTraining.parse(DocumentSnapshot snap)
      : reference = snap.reference,
        workRef = snap['work'],
        date = Date.fromTimeStamp(snap['date']),
        plan = snap['plan'],
        athletes = snap['athletes']?.cast<DocumentReference>() ??
            <DocumentReference>[];

  /*ScheduledTraining._(this.reference, this.workRef, {DateTime date, this.plan})
      : this.date = Date.fromDateTime(date);*/

  Allenamento get work => allenamenti[workRef];

  static FutureOr<void> create({
    @required DocumentReference work,
    @required DateTime date,
    Tabella plan,
    List<Athlete> athletes,
    WriteBatch batch,
  }) {
    if (batch == null)
      return userC.userReference.collection('schedules').add({
        'work': work,
        'date': date,
        'plan': plan?.reference,
        'athletes': athletes?.map((a) => a.reference)?.toList(),
      });
    batch.set(userC.userReference.collection('schedules').doc(), {
      'work': work,
      'date': date,
      'plan': plan?.reference,
      'athletes': athletes?.map((a) => a.reference)?.toList(),
    });
  }

  FutureOr<void> update({List<Athlete> athletes, WriteBatch batch}) {
    if (batch == null)
      reference.update({
        'athletes': athletes.map((a) => a.reference).toList(),
      });
    batch.update(reference, {
      'athletes': athletes.map((a) => a.reference).toList(),
    });
  }

  bool get isValid => date < Date.now(); // ?

  bool get isOk => workRef != null && date != null;

  /// do not call in athlete role: crash
  String get athletesAsList {
    if (athletes == null) return '';
    Iterable<Group> gs = Group.groups.where(
      (group) => group.athletes.every(
        (atleta) => athletes.contains(atleta.reference),
      ),
    );
    Iterable<Athlete> atls = athletes.map((a) => userC.rawAthletes[a]).where(
          (atleta) =>
              atleta != null &&
              atleta.isAthlete &&
              gs.every((group) => !group.athletes.contains(atleta)),
        );
    return gs.map((g) => g.name).followedBy(atls.map((a) => a.name)).join(', ');
  }
}
