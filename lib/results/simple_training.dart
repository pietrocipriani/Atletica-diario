import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/schedule/schedule.dart';

class SimpleTraining {
  final ScheduledTraining training;
  final String name;
  final List<SimpleRipetuta> ripetute;

  SimpleTraining.from(this.training)
      : assert(training.work != null),
        name = training.work!.name,
        ripetute = List.unmodifiable(
          training.work!.ripetute.map((r) => SimpleRipetuta.from(r)),
        );
}

class SimpleRipetuta {
  final String name;

  SimpleRipetuta(this.name);
  SimpleRipetuta.from(Ripetuta r) : name = r.template;

  @override
  String toString() => name;
}
