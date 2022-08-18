import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/training/training.dart';
import 'package:flutter/material.dart';

class Serie {
  /// the list of [Ripetuta] into `this` [Serie]
  final List<Ripetuta> ripetute = <Ripetuta>[];

  /// the unique [LayerLink] used by [CompositedTransformTarget] & [CompositedTransformFollower]
  final LayerLink link = LayerLink();

  /// * `nextRecupero`: [Recupero] after `ripetizioni`
  /// * `recupero`: [Recupero] between each `ripetizioni`
  final Recupero nextRecupero, recupero;

  /// `ripetizioni`: how many times repeat the same [Serie]
  int ripetizioni;

  /// default constructor
  Serie({
    final Iterable<Ripetuta>? ripetute,
    final Recupero? recupero,
    this.ripetizioni = 1,
    final Recupero? nextRecupero,
  })  : recupero = recupero ?? Recupero(isSerieRec: true),
        nextRecupero = nextRecupero ?? Recupero(isSerieRec: true) {
    if (ripetute != null) this.ripetute.addAll(ripetute);
  }

  /// creates a new instance from [DocumentSnapshot.data] from the [firestore]
  Serie.parse(final Training t, final Map raw)
      : recupero = Recupero(
          recupero: raw['recupero'] ?? 3 * 60,
          isSerieRec: true,
        ),
        nextRecupero = Recupero(
          recupero: raw['recuperoNext'] ?? 3 * 60,
          isSerieRec: true,
        ),
        ripetizioni = raw['times'] {
    raw['ripetute']?.forEach((raw) => Ripetuta.parse(this, raw));
    t.serie.add(this);
  }
  Serie.parseLegacy(final Training t, final Map<String, Object?> raw, final List<Object?> variants)
      : recupero = Recupero(recupero: raw['recupero'] ?? 3 * 60, isSerieRec: true),
        nextRecupero = Recupero(recupero: raw['recuperoNext'] ?? 3 * 60, isSerieRec: true),
        ripetizioni = raw['times'] as int {
    final List<Object?>? rawRipetute = raw['ripetute'] as List?;
    rawRipetute?.forEach((element) => Ripetuta.parseLegacy(this, raw, variants));
    t.serie.add(this);
  }

  /// converts `this` into a map to save it into [firestore]
  Map<String, dynamic> get asMap => {'recuperoNext': nextRecupero.recupero, 'recupero': recupero.recupero, 'times': ripetizioni, 'ripetute': ripetute.map((rip) => rip.asMap).toList()};

  /// returns the number of [Ripetuta] into `this` [Serie]
  int get ripetuteCount {
    return ripetute.fold<int>(0, (sum, rip) => sum + rip.ripetizioni) * ripetizioni;
  }

  Iterable<Recupero> get recuperi sync* {
    for (int i = 0; i < ripetizioni; i++) {
      for (Ripetuta r in ripetute) {
        yield* r.recuperi;
        if (r != ripetute.last) yield r.nextRecupero;
      }
      if (i != ripetizioni - 1) yield recupero;
    }
  }

  String get suggestName {
    final String inner = ripetute.map((r) => r.suggestName).join('-');
    if (ripetizioni == 1) return inner;
    if (ripetute.length == 1) return '${ripetizioni}x$inner';
    return '${ripetizioni}x($inner)';
  }
}
