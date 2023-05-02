import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/plan/plan.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';

void clearCache() {
  Training.cacheReset();
  Plan.cacheReset();
  ScheduledTraining.cacheReset();
  Result.cacheReset();
  Athlete.cacheReset();
}
