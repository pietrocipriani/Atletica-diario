import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/refactoring/model/target.dart';
import 'package:atletica/refactoring/model/tipologia.dart';
import 'package:atletica/refactoring/utils/distance.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/results/simple_training.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:atletica/training/serie.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/variant.dart';
import 'package:flutter/material.dart';

class _RowRip extends _RowRipRes {
  _RowRip({
    required final Ripetuta rip,
    final bool disabled = false,
  }) : super(
          name: rip.template,
          result: rip.target,
          disabled: disabled,
          tipologia: templates[rip.template]?.tipologia ?? Tipologia.corsaDist,
        );
}

class _RowRes extends _RowRipRes {
  _RowRes({
    required final MapEntry<SimpleRipetuta, Object?> res,
    final bool disabled = false,
    required final Tipologia tipologia,
  }) : super(
          name: res.key.name,
          result: res.value,
          disabled: disabled,
          tipologia: tipologia,
        );
}

abstract class _RowRipRes extends StatelessWidget {
  final String name;
  final Object? result;
  final bool disabled;
  final Tipologia tipologia;

  /// returns [Widget] for `Ripetuta` rows
  /// * `rip` is the [Ripetuta] to show
  /// * if `rip` is null then `ris` must be provided as result entry
  /// * if `disabled`, the [Row] is greyed out
  const _RowRipRes({
    required this.name,
    required this.result,
    this.disabled = false,
    required this.tipologia,
  }) : assert(result == null || result is Target || result is Duration || result is Distance);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: name,
              style: disabled ? null : TextStyle(color: theme.primaryColorDark),
            ),
            if (result != null)
              TextSpan(
                text: ' in ',
                style: TextStyle(fontWeight: FontWeight.normal),
              ),
            if (result != null)
              TextSpan(
                text: tipologia.formatTarget(result is Target ? (result as Target)[TargetCategory.values.first] : result), // TODO
              )
          ],
          style: disabled ? theme.textTheme.overline!.copyWith(color: theme.disabledColor) : theme.textTheme.overline!, // TODO: [DefaultTextTheme]
        ),
      ),
    );
  }
}

class _RowRec extends StatelessWidget {
  final Recupero rec;
  final bool disabled;

  /// returns [Widget] for `Recupero` rows
  /// * `rec` is the [Recupero] to show
  /// * if `isSerieRec`, the [Row] is highlighted
  /// * if `disabled`, the [Row] is greyed out
  _RowRec({required this.rec, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 1,
            color: (rec.isSerieRec && !disabled) ? theme.primaryColor : theme.disabledColor,
          ),
        ),
        RichText(
          text: TextSpan(
            text: rec.toString(),
            style: disabled ? theme.textTheme.overline!.copyWith(color: theme.disabledColor) : theme.textTheme.overline,
            children: [
              TextSpan(
                text: ' recupero',
                style: TextStyle(fontWeight: FontWeight.normal),
              )
            ],
          ),
        )
      ],
    );
  }
}

// TODO: migrate this shit
/// utility class that builds training description
class TrainingDescription {
  /// creates the description from `result`
  static Iterable<Widget> fromResults(final Result result) => result.asIterable.map((e) => _RowRes(
        res: e,
        tipologia: Tipologia.corsaDist,
      ));

  /// creates the description from `training` with optional `result`
  /// * `result` can be incompatible, if so it's ignored
  /// * if `disabled`, all the [Row]s are greyed out
  static Iterable<Widget> fromTraining(
    final Training training, [
    Result? result,
    bool disabled = false,
  ]) sync* {
    final bool useResult = result != null && result.isCompatible(training);

    final List<Ripetuta> rips = training.ripetute.toList();
    final List<MapEntry<SimpleRipetuta, Object?>>? ress = useResult ? result.results.entries.toList() : null;
    final List<Recupero> recs = training.recuperi.toList();

    for (int i = 0; i < rips.length; i++) {
      if (ress != null && ress[i].value != null)
        yield _RowRes(
          res: ress[i],
          tipologia: templates[rips[i].template]?.tipologia ?? Tipologia.corsaDist,
          disabled: disabled,
        );
      else
        yield _RowRip(
          rip: rips[i],
          disabled: disabled,
        );
      if (i < recs.length) yield _RowRec(rec: recs[i], disabled: disabled);
    }
  }

  static Iterable<Widget> fromSerie(
    final List<Serie> serie, [
    final bool disabled = false,
  ]) sync* {
    final List<Ripetuta> rips = serie.expand((s) => Iterable.generate(s.ripetizioni, (i) => s)).expand((s) => s.ripetute).expand((r) => Iterable.generate(r.ripetizioni, (i) => r)).toList();
    final List<Recupero> recs = () sync* {
      for (Serie s in serie) {
        yield* s.recuperi;
        if (s != serie.last) yield s.nextRecupero;
      }
    }()
        .toList();
    for (int i = 0; i < rips.length; i++) {
      yield _RowRip(rip: rips[i], disabled: disabled);
      if (i < recs.length) yield _RowRec(rec: recs[i], disabled: disabled);
    }
  }
}
