import 'package:Atletica/ripetuta/ripetuta.dart';
import 'package:Atletica/training/allenamento.dart';

class SimpleTraining {
  final List<SimpleRipetuta> ripetute;

  SimpleTraining.from(Allenamento training)
      : ripetute = List.unmodifiable(
          training.ripetute.map((r) => SimpleRipetuta.from(r)),
        );
}

class SimpleRipetuta {
  final String name;

  SimpleRipetuta(this.name);
  SimpleRipetuta.from(Ripetuta r) : name = r.template;
}
