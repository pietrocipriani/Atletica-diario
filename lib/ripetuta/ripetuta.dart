import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/utils/cast.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/training/serie.dart';
import 'package:flutter/material.dart';

class Ripetuta {
  final LayerLink link = LayerLink();

  String _template;
  SimpleTemplate? _resolvedTemplate;

  String get template => _template;
  set template(String template) {
    _template = template;
    _resolvedTemplate = null;
  }

  SimpleTemplate get resolveTemplate =>
      _resolvedTemplate ?? templates[template]!;
  bool get hasConcreteTemplate => templates.containsKey(template);

  /// `target` in secondi per `Tipologia.corsaDist`, in metri per `Tipologia.salto, Tipologia.lancio`, in metri per `Tipologia.corsaTemp`
  final Target target;

  int ripetizioni;
  Recupero nextRecupero, recupero;

  Ripetuta({
    required String template,
    this.ripetizioni = 1,
    final Recupero? nextRecupero,
    final Recupero? recupero,
    final Target? target,
  })  : _template = template,
        nextRecupero = nextRecupero ?? Recupero(),
        recupero = recupero ?? Recupero(),
        target = target ?? Target.empty();

  Ripetuta.parse(final Serie serie, final Map<String, Object?> raw)
      // TODO: better to throw?
      : _template = cast(raw['template'], '??'),
        target = Target.parse(raw['target']),
        recupero = Recupero(recupero: raw['recupero']),
        ripetizioni = cast(raw['times'], 1),
        nextRecupero = Recupero(recupero: raw['recuperoNext']) {
    serie.ripetute.add(this);
  }
  Ripetuta.parseLegacy(final Serie serie, final Map<String, Object?> raw,
      final List<Object?> variants)
      : _template = cast(raw['template'], '??'),
        target = Target.parse(variants.first),
        recupero = Recupero(recupero: raw['recupero']),
        ripetizioni = cast(raw['times'], 1),
        nextRecupero = Recupero(recupero: raw['recuperoNext']) {
    variants.removeAt(0);
    serie.ripetute.add(this);
  }

  Map<String, dynamic> get asMap => {
        'template': template,
        'recupero': recupero.recupero,
        'times': ripetizioni,
        'recuperoNext': nextRecupero.recupero,
        'target': target.asMap,
      };

  Iterable<Recupero> get recuperi sync* {
    for (int i = 0; i < ripetizioni - 1; i++) yield recupero;
  }

  String get suggestName {
    if (ripetizioni == 1) return template;
    return '${ripetizioni}x$template';
  }
}
