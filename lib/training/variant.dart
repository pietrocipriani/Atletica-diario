import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/training/allenamento.dart';

class Variant {
  /// in case of default values... actually useless
  static const Map<String, dynamic> emptyMap = {'targets': []};

  final Map<Ripetuta, double> targets;

  Map<String, dynamic> asMap(final Allenamento a) {
    return {
      'targets': a.serie
          .expand((s) => s.ripetute)
          .map((r) => this.targets[r])
          .toList(),
    };
  }

  Variant.parse(final Map<String, dynamic> raw, final Allenamento a)
      : targets = Map.fromIterables(
          a.serie.expand((s) => s.ripetute),
          raw['targets'].cast<double>(),
        );
  Variant.from(final Variant a) : targets = Map.from(a.targets);
  Variant.fromOldMode(final Allenamento a)
      : targets = Map.fromIterable(
          a.serie.expand((s) => s.ripetute),
          key: (r) => r,
          value: (r) => r.target,
        );
}
