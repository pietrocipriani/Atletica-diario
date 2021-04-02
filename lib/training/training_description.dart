import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/results/simple_training.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:atletica/training/allenamento.dart';
import 'package:atletica/training/serie.dart';
import 'package:flutter/material.dart';

/// utility class that builds training description
class TrainingDescription {
  /// returns [Widget] for `Ripetuta` rows
  /// * `rip` is the [Ripetuta] to show
  /// * if `rip` is null then `ris` must be provided as result entry
  /// * if `disabled`, the [Row] is greyed out
  static Widget _rowRip(
    final Ripetuta rip,
    final MapEntry<SimpleRipetuta, double> ris,
    final Color primaryColorDark,
    final TextStyle overline, [
    final bool disabled = false,
  ]) {
    assert((rip == null) != (ris == null),
        'cannot pass both the rip and the result');
    final String name = ris?.key?.name ?? rip?.template;
    final double result = ris?.value ?? rip?.target;
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: name,
              style: TextStyle(color: primaryColorDark),
            ),
            if (result != null)
              TextSpan(
                text: ' in ',
                style: TextStyle(
                  color: disabled ? Colors.grey[300] : null,
                  fontWeight: FontWeight.normal,
                ),
              ),
            if (result != null)
              TextSpan(
                text:
                    (templates[rip?.template]?.tipologia ?? Tipologia.corsaDist)
                        .targetFormatter(result),
                style: TextStyle(
                  color: (rip == null && ris == null) || disabled
                      ? Colors.grey[300]
                      : null,
                ),
              )
          ],
          style: overline,
        ),
      ),
    );
  }

  /// returns [Widget] for `Recupero` rows
  /// * `rec` is the [Recupero] to show
  /// * if `isSerieRec`, the [Row] is highlighted
  /// * if `disabled`, the [Row] is greyed out
  static Widget _rowRec(
    final Recupero rec,
    final bool isSerieRec,
    final Color primaryColor,
    final Color disabledColor,
    final TextStyle overline, [
    final bool disabled = false,
  ]) {
    if (rec == null) return Container();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 1,
            color: ((isSerieRec ?? false) && !disabled)
                ? primaryColor
                : disabledColor,
          ),
        ),
        RichText(
          text: TextSpan(text: rec.toString(), style: overline, children: [
            TextSpan(
              text: ' recupero',
              style: TextStyle(fontWeight: FontWeight.normal),
            )
          ]),
        )
      ],
    );
  }

  /// creates the description from `result`
  static Iterable<Widget> fromResults(
    BuildContext context,
    Result result,
  ) {
    return result.asIterable.map((e) => _rowRip(
          null,
          e,
          Theme.of(context).primaryColorDark,
          Theme.of(context).textTheme.overline,
        ));
  }

  /// creates the description from `training` with optional `result`
  /// * `result` can be incompatible, if so it's ignored
  /// * if `disabled`, all the [Row]s are greyed out
  static Iterable<Widget> fromTraining(
    BuildContext context,
    final Allenamento training, [
    Result result,
    bool disabled = false,
  ]) sync* {
    final ThemeData theme = Theme.of(context);
    final bool useResult = result != null &&
        result.isCompatible(training) &&
        result.results.values.any((r) => r != null);

    TextStyle overline = theme.textTheme.overline;
    if (disabled) overline = overline.copyWith(color: Colors.grey[300]);
    final Color primaryColorDark = theme.primaryColorDark;
    final Color primaryColor = theme.primaryColor;
    final Color disabledColor = theme.disabledColor;

    int index = 0;
    for (final Serie s in training.serie)
      for (int i = 1; i <= s.ripetizioni; i++)
        for (final Ripetuta r in s.ripetute)
          for (int j = 1; j <= r.ripetizioni; j++) {
            yield _rowRip(
              useResult ? null : r,
              useResult ? result.asIterable.skip(index++).first : null,
              primaryColorDark,
              overline,
              disabled,
            );
            if (s != training.serie.last ||
                r != s.ripetute.last ||
                i < s.ripetizioni ||
                j < r.ripetizioni)
              yield _rowRec(
                j == r.ripetizioni
                    ? r == s.ripetute.last
                        ? i == s.ripetizioni
                            ? s == training.serie.last
                                ? null
                                : s.nextRecupero
                            : s.recupero
                        : r.nextRecupero
                    : r.recupero,
                j == r.ripetizioni && r == s.ripetute.last,
                primaryColor,
                disabledColor,
                overline,
                disabled,
              );
          }
  }
}
