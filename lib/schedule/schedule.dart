import 'dart:async';
import 'dart:collection';

import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/athlete/group.dart';
import 'package:atletica/cache.dart';
import 'package:atletica/date.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/plan/plan.dart';
import 'package:atletica/main.dart' show IterableExtension;
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

class ScheduledTraining with Notifier<ScheduledTraining> {
  static final Cache<DocumentReference, ScheduledTraining> _cache = Cache();
  static final SplayTreeMap<Date, List<ScheduledTraining>> cachedByDate =
      SplayTreeMap();

  static void Function(Callback c) signInGlobal = _cache.signIn;
  static void Function(Callback c) signOutGlobal = _cache.signOut;

  static void cacheReset() {
    _cache.reset();
    cachedByDate.clear();
  }

  static void remove(final ScheduledTraining st) {
    _cache.remove(st.reference);
    final List<ScheduledTraining>? sts = cachedByDate[st.date];
    if (sts == null) return;
    sts.remove(st);
    if (sts.isEmpty) cachedByDate.remove(st.date);
    _cache.notifyAll(st, Change.DELETED);
  }

  static Iterable<ScheduledTraining> get scheduledTrainings => _cache.values;
  static Iterable<ScheduledTraining> inRange(final Date start, final Date end) {
    return cachedByDate.entries
        .skipWhile((e) => e.key < start)
        .takeWhile((e) => e.key <= end)
        .expand((e) => e.value);
  }

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

  static List<ScheduledTraining> ofDate(final Date date) {
    return cachedByDate[date] ?? List.empty();
  }

  static ScheduledTraining? ofDateRef(
      final Date date, final DocumentReference training) {
    return ofDate(date).firstWhereNullable((s) => s.workRef == training);
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
  final DocumentReference? plan;
  final Set<DocumentReference> _athletes;
  Iterable<Athlete> get athletes => Athlete.getAthletes(_athletes);
  Set<DocumentReference> get athletesRefs => _athletes;

  factory ScheduledTraining.parse(
    final DocumentSnapshot<Map<String, Object?>> raw,
  ) {
    final ScheduledTraining a =
        _cache[raw.reference] ??= ScheduledTraining._parse(raw);
    _cache.notifyAll(a, Change.ADDED);
    return a;
  }
  ScheduledTraining._parse(DocumentSnapshot snap)
      : reference = snap.reference,
        workRef = snap['work'],
        date = Date.fromTimeStamp(snap['date']),
        plan = snap['plan'],
        _athletes = Set.from((snap.getNullable('athletes') as List?)
                ?.cast<DocumentReference>() ??
            Iterable.empty()) {
    (cachedByDate[date] ??= []).add(this);
  }

  static void updateStatic(
    final ScheduledTraining a,
    final DocumentSnapshot<Map<String, Object?>> raw,
  ) {
    a._athletes.clear();
    a._athletes
        .addAll(raw['athletes']?.cast<DocumentReference>() ?? Iterable.empty());
    _cache.notifyAll(a, Change.UPDATED);
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
    batch.set(Globals.helper.userReference.collection('schedules').doc(), {
      'work': work.reference,
      'date': date,
      'plan': plan?.reference,
      'athletes':
          (athletes ?? Athlete.athletes.map((e) => e.reference)).toList(),
    });
  }

  Future<void> update({
    List<DocumentReference>? athletes,
    List<DocumentReference>? removedAthletes,
    WriteBatch? batch,
  }) async {
    if (batch == null) {
      final WriteBatch b = firestore.batch();
      await update(
          athletes: athletes, removedAthletes: removedAthletes, batch: b);
      return await b.commit();
    }
    final Set<DocumentReference> remainingAthletes = Set.from(_athletes);
    if (removedAthletes != null) remainingAthletes.removeAll(removedAthletes);
    if (athletes != null) remainingAthletes.addAll(athletes);
    if (remainingAthletes.isEmpty)
      batch.delete(reference);
    else
      batch.update(reference, {'athletes': remainingAthletes.toList()});
  }

  bool get isValid => date < Date.now(); // ?

  /// do not call in athlete role: crash
  String get athletesAsList {
    final List<Athlete> athletes = Athlete.getAthletes(_athletes).toList();
    final List<Group> gs =
        Group.groups.where((group) => group.isContainedIn(athletes)).toList();
    gs.forEach((g) => g.athletes.forEach(athletes.remove));
    return gs
        .map((g) => g.name)
        .followedBy(athletes.map((a) => a.name))
        .join(', ');
  }
}
