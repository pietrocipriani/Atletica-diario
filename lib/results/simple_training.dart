import 'package:Atletica/ripetuta/ripetuta.dart';
import 'package:Atletica/training/allenamento.dart';

class SimpleTraining {
  final String name;
  final List<SimpleRipetuta> ripetute;

  SimpleTraining.from(Allenamento training)
      : name = training.name,
        ripetute = List.unmodifiable(
          training.ripetute.map((r) => SimpleRipetuta.from(r)),
        );
}

class SimpleRipetuta {
  final String name;

  SimpleRipetuta(this.name);
  SimpleRipetuta.from(Ripetuta r) : name = r.template;

  @override
  String toString() => name;
}
