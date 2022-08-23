/* import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/training/serie.dart';
import 'package:atletica/training/training.dart';

// TODO: remove this shit
class Variant {
  /// in case of default values... actually useless
  static const Map<String, dynamic> emptyMap = {'targets': []};

  final Map<Ripetuta, Target> targets;

  Map<String, dynamic> asMap([final Training? a]) => {
        'targets': (a?.serie.expand((s) => s.ripetute).map((r) => this.targets[r]) ?? targets.values).toList(),
      };

  Variant.parse(final Map<String, dynamic> raw, final Training a)
      : targets = Map.fromIterables(
          a.serie.expand((s) => s.ripetute),
          raw['targets'].map((r) => Target(targetMale: r, targetFemale: r)),
        ) {
    a.variants.add(this);
  }
  Variant.from(final Variant a) : targets = Map.from(a.targets);
  Variant.fromOldMode(final Training a)
      : targets = Map.fromIterable(
          a.serie.expand((s) => s.ripetute),
          key: (r) => r as Ripetuta,
          value: (r) => (r as Ripetuta).target,
        ) {
    a.variants.add(this);
  }
  Variant.fromSerie(final List<Serie> serie)
      : targets = Map.fromIterable(
          serie.expand<Ripetuta>((s) => s.ripetute),
          key: (_) => _,
          value: (r) => r.target,
        );

  double? operator [](final Ripetuta? rip) {
    if (rip == null) return null;
    return targets[rip];
  }

  operator []=(final Ripetuta rip, final double? t) => targets[rip] = t;
}
 */