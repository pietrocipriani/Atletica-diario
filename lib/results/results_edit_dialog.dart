import 'package:Atletica/results/result.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:Atletica/ripetuta/template.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

final List<IconData> icons = const [
  Mdi.emoticonExcitedOutline,
  Mdi.emoticonNeutralOutline,
  Mdi.emoticonConfusedOutline,
  Mdi.emoticonSadOutline,
  Mdi.emoticonDeadOutline,
];

Future<void> showResultsEditDialog(
  BuildContext context,
  Result results,
  Future<void> Function(Result results) save,
) =>
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: ResultsEditDialog(results),
        title: Text('Modifica i risultati'),
        scrollable: true,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // TODO: remove changes
              Navigator.pop(context);
            },
            child: Text('Chiudi'),
          ),
          TextButton(
            onPressed: () async {
              await save(results);
              Navigator.pop(context);
            },
            child: Text('Salva'),
          )
        ],
      ),
    );

class ResultsEditDialog extends StatefulWidget {
  final Result results;

  ResultsEditDialog(this.results);

  @override
  _ResultsEditDialogState createState() =>
      _ResultsEditDialogState(results.ripetute);
}

class _ResultsEditDialogState extends State<ResultsEditDialog> {
  final Map<SimpleRipetuta, FocusNode> nodes;
  final List<SimpleRipetuta> keys;

  _ResultsEditDialogState(Iterable<SimpleRipetuta> rips)
      : nodes = Map.fromIterable(rips,
            key: (rip) => rip, value: (rip) => FocusNode()),
        keys = List.unmodifiable(rips);

  bool _acceptable(String s) {
    if (s == null || s.isEmpty) return true;
    final bool match = Tipologia.corsaDist.targetValidator(s);
    print('is |$s| acceptable? $match');
    print(
        'I should return ${s != null} && ($match || ${s.isEmpty}) = ${s != null && (match || s.isEmpty)}');
    return s != null && (match || s.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle overline = Theme.of(context).textTheme.overline;
    final TextStyle overlineBC = overline.copyWith(
        color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.bold);

    final Color emojiSelected = Theme.of(context).primaryColorDark;
    final Color emojiDisabled = Colors.grey[300];
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: widget.results.asIterable.map<Widget>((r) {
          return Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(child: Text('${r.key.name}:', style: overlineBC)),
              Expanded(
                child: TextFormField(
                  textAlign: TextAlign.right,
                  focusNode: nodes[r.key],
                  initialValue: Tipologia.corsaDist.targetFormatter(r.value),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: overline,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                  ),
                  validator: (value) =>
                      _acceptable(value) ? null : 'es 1\' 20"50',
                  onChanged: (value) {
                    if (_acceptable(value))
                      widget.results.results[r.key] =
                          Tipologia.corsaDist.targetParser(value);
                  },
                  onFieldSubmitted: (value) {
                    if (_acceptable(value))
                      widget.results
                          .set(r.key, Tipologia.corsaDist.targetParser(value));

                    Iterable<SimpleRipetuta> nextIterable =
                        keys.skipWhile((key) => key != r.key);
                    final SimpleRipetuta nextRip = nextIterable.firstWhere(
                      (key) => widget.results[key] == null,
                      orElse: () {
                        if (value != null &&
                            Tipologia.corsaDist.targetValidator(value))
                          nextIterable = nextIterable.skip(1);
                        if (nextIterable.isEmpty) return null;
                        return nextIterable.first;
                      },
                    );
                    if (nextRip != null) nodes[nextRip].requestFocus();
                  },
                ),
              ),
            ],
          );
        }).followedBy([
          Container(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: Iterable<int>.generate(icons.length, (i) => i)
                .map((i) => fatigueEmoji(i, i == widget.results.fatigue))
                .toList(),
          )
        ]).toList(),
      ),
    );
  }

  Widget fatigueEmoji(final int value, final bool selected) {
    return IconButton(
      icon: Icon(
        icons[value],
        size: 42,
        color: selected
            ? Color.lerp(Colors.green, Colors.red, value / icons.length)
            : Colors.grey[300],
      ),
      onPressed: () => setState(() => widget.results.fatigue = selected ? null : value),
    );
  }
}
