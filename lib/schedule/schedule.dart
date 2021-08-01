import 'dart:async';

import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/athlete/group.dart';
import 'package:atletica/cache.dart';
import 'package:atletica/date.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/plan/plan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime bareDT([DateTime? dt]) {
  dt ??= DateTime.now();
  dt = dt.toUtc();
  return DateTime.utc(dt.year, dt.month, dt.day);
}

DateTime nextStartOfWeek([DateTime? dt]) {
  dt ??= DateTime.now();
  dt = bareDT(dt);
  if (dt.weekday == DateTime.monday) return dt;
  final int shift = 7 - (dt.weekday - DateTime.monday) % 7;
  return dt.add(Duration(days: shift));
}

class ScheduledTraining {
  static final Cache<DocumentReference, ScheduledTraining> _cache = Cache();

  static void Function(Callback c) signIn = _cache.signIn;
  static void Function(Callback c) signOut = _cache.signOut;

  static void Function() cacheReset = _cache.reset;

  static void remove(final DocumentReference ref) {
    final ScheduledTraining? a = _cache.remove(ref);
    if (a != null) _cache.notifyAll(a);
  }

  static Iterable<ScheduledTraining> get trainings => _cache.values;

  static bool get isEmpty => _cache.isEmpty;
  static bool get isNotEmpty => _cache.isNotEmpty;

  static ScheduledTraining? tryOf(final DocumentReference? ref) {
    if (ref == null) return null;
    try {
      return ScheduledTraining.of(ref);
    } on StateError {
      return null;
    }
  }

  factory ScheduledTraining.of(final DocumentReference ref) {
    final ScheduledTraining? a = _cache[ref];
    if (a == null)
      throw StateError('cannot find ScheduledTraining of ${ref.path}');
    return a;
  }

  final DocumentReference reference;
  final DocumentReference workRef;
  final Date date;
  final DocumentReference plan;
  final List<DocumentReference> _athletes;
  Iterable<Athlete> get athletes => Athlete.getAthletes(_athletes);
  List<DocumentReference> get athletesRefs => _athletes;

  factory ScheduledTraining.parse(final DocumentSnapshot raw) {
    final ScheduledTraining a =
        _cache[raw.reference] ??= ScheduledTraining._parse(raw);
    _cache.notifyAll(a);
    return a;
  }
  ScheduledTraining._parse(DocumentSnapshot snap)
      : reference = snap.reference,
        workRef = snap['work'],
        date = Date.fromTimeStamp(snap['date']),
        plan = snap['plan'],
        _athletes = snap['athletes']?.cast<DocumentReference>() ??
            <DocumentReference>[];

  factory ScheduledTraining.update(final DocumentSnapshot raw) {
    final ScheduledTraining a = ScheduledTraining.of(raw.reference);
    return a;
  }

  Training? get work => Training.tryOf(workRef);

  static Future<void> create({
    required Training work,
    required DateTime date,
    Plan? plan,
    List<DocumentReference>? athletes,
    WriteBatch? batch,
  }) async {
    if (batch == null) {
      final WriteBatch b = firestore.batch();
      await create(
          work: work, date: date, plan: plan, athletes: athletes, batch: b);
      return await b.commit();
    }
    batch.set(userC.userReference.collection('schedules').doc(), {
      'work': work.reference,
      'date': date,
      'plan': plan?.reference,
      'athletes': athletes?.toList(),
    });
  }

  FutureOr<void> update({
    List<DocumentReference>? athletes,
    List<DocumentReference>? removedAthletes,
    WriteBatch? batch,
  }) {
    if (batch == null) {
      final WriteBatch b = firestore.batch();
      update(athletes: athletes, removedAthletes: removedAthletes, batch: b);
      return b.commit();
    }
    final Set<DocumentReference> remainingAthletes = Set.from(_athletes);
    if (removedAthletes != null)
      remainingAthletes.removeWhere(removedAthletes.contains);
    if (athletes != null)
      remainingAthletes
          .addAll(athletes.where((a) => !remainingAthletes.contains(a)));
    if (remainingAthletes.isEmpty)
      batch.delete(reference);
    else
      batch.update(reference, {'athletes': remainingAthletes.toList()});
  }

  bool get isValid => date < Date.now(); // ?

  bool get isOk => workRef != null && date != null;

  /// do not call in athlete role: crash
  String get athletesAsList {
    final List<Athlete> athletes = Athlete.getAthletes(_athletes).toList();
    Iterable<Group> gs =
        Group.groups.where((group) => group.isContainedIn(athletes));
    gs.forEach((g) => g.athletes.forEach(athletes.remove));
    return gs
        .map((g) => g.name)
        .followedBy(athletes.map((a) => a.name))
        .join(', ');
  }
}
