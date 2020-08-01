import 'package:AtleticaCoach/results/simple_training.dart';
import 'package:AtleticaCoach/ripetuta/template.dart';
import 'package:flutter/material.dart';

Future<void> showResultsEditDialog(
  BuildContext context,
  Map<SimpleRipetuta, double> results,
  Future<void> Function(Map<SimpleRipetuta, double> results) save,
) =>
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: ResultsEditDialog(results),
        title: Text('Modifica i risultati'),
        scrollable: true,
        actions: <Widget>[
          FlatButton(onPressed: null, child: Text('Chiudi')),
          FlatButton(
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
  final Map<SimpleRipetuta, double> results;

  ResultsEditDialog(this.results);

  @override
  _ResultsEditDialogState createState() =>
      _ResultsEditDialogState(results.keys);
}

class _ResultsEditDialogState extends State<ResultsEditDialog> {
  final Map<SimpleRipetuta, FocusNode> nodes;
  final List<SimpleRipetuta> keys;

  _ResultsEditDialogState(Iterable<SimpleRipetuta> rips)
      : nodes = Map.fromIterable(rips,
            key: (rip) => rip, value: (rip) => FocusNode()),
        keys = List.unmodifiable(rips);

  bool _acceptable(String s) =>
      s != null &&
      (Tipologia.corsaDist.targetValidator.stringMatch(s) == s || s.isEmpty);

  @override
  Widget build(BuildContext context) {
    final TextStyle overline = Theme.of(context).textTheme.overline;
    final TextStyle overlineBC = overline.copyWith(
        color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.bold);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: widget.results.entries.map((r) {
          return Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(child: Text('${r.key.name}:', style: overlineBC)),
              Expanded(
                child: TextFormField(
                  textAlign: TextAlign.right,
                  focusNode: nodes[r.key],
                  initialValue: Tipologia.corsaDist.targetFormatter(r.value),
                  autovalidate: true,
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
                      widget.results[r.key] =
                          Tipologia.corsaDist.targetParser(value);
                  },
                  onFieldSubmitted: (value) {
                    if (_acceptable(value))
                      widget.results[r.key] =
                          Tipologia.corsaDist.targetParser(value);

                    Iterable<SimpleRipetuta> nextIterable =
                        keys.skipWhile((key) => key != r.key);
                    final SimpleRipetuta nextRip = nextIterable.firstWhere(
                      (key) => widget.results[key] == null,
                      orElse: () {
                        if (value != null &&
                            Tipologia.corsaDist.targetValidator
                                    .stringMatch(value) ==
                                value) nextIterable = nextIterable.skip(1);
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
        }).toList(),
      ),
    );
  }
}
