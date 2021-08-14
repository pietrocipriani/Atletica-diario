import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/results/simple_training.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/variant.dart';
import 'package:flutter/material.dart';

class _RowRip extends _RowRipRes {
  _RowRip({
    required final Ripetuta rip,
    required final Variant active,
    final bool disabled = false,
  }) : super(
          name: rip.template,
          result: active[rip],
          disabled: disabled,
          tipologia: templates[rip.template]?.tipologia ?? Tipologia.corsaDist,
        );
}

class _RowRes extends _RowRipRes {
  _RowRes({
    required final MapEntry<SimpleRipetuta, double?> res,
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
  final double? result;
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
  });

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
              style: TextStyle(color: theme.primaryColorDark),
            ),
            if (result != null)
              TextSpan(
                text: ' in ',
                style: TextStyle(fontWeight: FontWeight.normal),
              ),
            if (result != null)
              TextSpan(
                text: tipologia.targetFormatter(result),
              )
          ],
          style: disabled
              ? theme.textTheme.overline!.copyWith(color: theme.disabledColor)
              : theme.textTheme.overline!,
        ),
      ),
    );
  }
}

class _RowRec extends StatelessWidget {
  final Recupero rec;
  final bool isSerieRec;
  final bool disabled;

  /// returns [Widget] for `Recupero` rows
  /// * `rec` is the [Recupero] to show
  /// * if `isSerieRec`, the [Row] is highlighted
  /// * if `disabled`, the [Row] is greyed out
  _RowRec({
    required this.rec,
    required this.isSerieRec,
    this.disabled = false,
  });

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
            color: (isSerieRec && !disabled)
                ? theme.primaryColor
                : theme.disabledColor,
          ),
        ),
        RichText(
          text: TextSpan(
              text: rec.toString(),
              style: theme.textTheme.overline,
              children: [
                TextSpan(
                  text: ' recupero',
                  style: TextStyle(fontWeight: FontWeight.normal),
                )
              ]),
        )
      ],
    );
  }
}

/// utility class that builds training description
class TrainingDescription {
  /// creates the description from `result`
  static Iterable<Widget> fromResults(final Result result) =>
      result.asIterable.map((e) => _RowRes(
            res: e,
            tipologia: Tipologia.corsaDist,
          ));

  /// creates the description from `training` with optional `result`
  /// * `result` can be incompatible, if so it's ignored
  /// * if `disabled`, all the [Row]s are greyed out
  static Iterable<Widget> fromTraining(
    final Training training,
    Variant active, [
    Result? result,
    bool disabled = false,
  ]) sync* {
    final bool useResult = result != null && result.isCompatible(training);

    final List<Ripetuta> rips = training.ripetute.toList();
    final List<MapEntry<SimpleRipetuta, double?>>? ress =
        useResult ? result.results.entries.toList() : null;
    final List<Recupero> recs = training.recuperi.toList();

    for (int i = 0; i < rips.length; i++) {
      if (ress != null && ress[i].value != null)
        yield _RowRes(
          res: ress[i],
          tipologia:
              templates[rips[i].template]?.tipologia ?? Tipologia.corsaDist,
          disabled: disabled,
        );
      else
        yield _RowRip(
          rip: rips[i],
          active: active,
          disabled: disabled,
        );
      if (i < recs.length)
        yield _RowRec(
          rec: recs[i],
          isSerieRec: training.isSerieRec(i),
          disabled: disabled,
        );
    }
  }
}
