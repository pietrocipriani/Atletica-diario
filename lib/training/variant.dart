import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/training/training.dart';

class Variant {
  /// in case of default values... actually useless
  static const Map<String, dynamic> emptyMap = {'targets': []};

  final Map<Ripetuta, double?> targets;

  Map<String, dynamic> asMap(final Training a) => {
        'targets': a.serie
            .expand((s) => s.ripetute)
            .map((r) => this.targets[r])
            .toList(),
      };

  Variant.parse(final Map<String, dynamic> raw, final Training a)
      : targets = Map.fromIterables(
          a.serie.expand((s) => s.ripetute),
          raw['targets'].cast<double?>(),
        ) {
    a.variants.add(this);
  }
  Variant.from(final Variant a) : targets = Map.from(a.targets);
  Variant.fromOldMode(final Training a)
      : targets = Map.fromIterable(
          a.serie.expand((s) => s.ripetute),
          key: (r) => r,
          value: (r) => r.target,
        ) {
    a.variants.add(this);
  }

  double? operator [](final Ripetuta? rip) {
    if (rip == null) return null;
    return targets[rip];
  }

  operator []=(final Ripetuta rip, final double? t) => targets[rip] = t;
}
