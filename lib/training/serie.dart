import 'package:Atletica/recupero/recupero.dart';
import 'package:Atletica/ripetuta/ripetuta.dart';
import 'package:flutter/material.dart';

class Serie {

  /// the list of [Ripetuta] into `this` [Serie]
  List<Ripetuta> ripetute = <Ripetuta>[];

  /// the unique [LayerLink] used by [CompositedTransformTarget] & [CompositedTransformFollower]
  final LayerLink link = LayerLink();

  /// * `nextRecupero`: [Recupero] after `ripetizioni`
  /// * `recupero`: [Recupero] between each `ripetizioni`
  Recupero nextRecupero, recupero;

  /// `ripetizioni`: how many times repeat the same [Serie]
  int ripetizioni;

  /// default constructor
  Serie(
      {Iterable<Ripetuta> ripetute,
      this.recupero,
      this.ripetizioni = 1,
      this.nextRecupero}) {
    recupero ??= Recupero();
    nextRecupero ??= Recupero();
    if (ripetute != null) this.ripetute.addAll(ripetute);
  }
  
  /// creates a new instance from [DocumentSnapshot.data] from the [firestore]
  Serie.parse(Map raw) {
    recupero = Recupero(raw['recupero'] ?? 3 * 60);
    nextRecupero = Recupero(raw['recuperoNext'] ?? 3 * 60);
    ripetizioni = raw['times'];
    ripetute = raw['ripetute']
            ?.map<Ripetuta>((raw) => Ripetuta.parse(raw))
            ?.toList() ??
        <Ripetuta>[];
  }

  /// converts `this` into a map to save it into [firestore]
  Map<String, dynamic> get asMap => {
        'recuperoNext': nextRecupero.recupero,
        'recupero': recupero.recupero,
        'times': ripetizioni,
        'ripetute': ripetute.map((rip) => rip.asMap).toList()
      };

  /// returns the number of [Ripetuta] into `this` [Serie]
  int get ripetuteCount {
    return ripetute.fold(0, (sum, rip) => sum + rip.ripetizioni) * ripetizioni;
  }
}
