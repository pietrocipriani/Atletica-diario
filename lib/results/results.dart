import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/date.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/training/training.dart';

class Results {
  /// the `key` is the reference for the Athlete
  final Map<Athlete, Result> results = {};
  final Date date;
  final Training training;
  final int ripetuteCount;

  Results({
    required this.training,
    required this.date,
    Iterable<Athlete>? athletes,
  }) : ripetuteCount = training.ripetute.length {
    if (athletes == null || athletes.isEmpty)
      athletes = Athlete.athletes.toList();
    for (final Athlete a in athletes) results[a] = Result.temp(training, date);
  }

  bool update(final Athlete athlete, final Result updated) {
    if (updated.ripetute.length != training.ripetute.length ||
        updated.isNotCompatible(training)) return false;
    this.results[athlete] = updated;
    return true;
  }
}
