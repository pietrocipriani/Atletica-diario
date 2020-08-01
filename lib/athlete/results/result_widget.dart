import 'package:AtleticaCoach/athlete/results/results_route.dart';
import 'package:AtleticaCoach/global_widgets/custom_expansion_tile.dart';
import 'package:AtleticaCoach/ripetuta/template.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

MapEntry parseRawResult(String rawResult) {
  if (rawResult == null) return null;
  final List<String> splitted = rawResult.split(':');
  if (splitted.length != 2) return null;
  if (splitted[0].isEmpty || splitted[1].isEmpty) return null;
  final double value = double.tryParse(splitted[1]);
  if (value == null) return null;
  return MapEntry(splitted[0], value);
}

class ResultWidget extends StatelessWidget {
  final DocumentSnapshot snap;
  final DateTime date;
  final String training;

  ResultWidget(this.snap)
      : date = DateTime.parse(snap.documentID),
        training = snap['training'];

  @override
  Widget build(BuildContext context) => CustomExpansionTile(
        title: training,
        subtitle: Text(DateFormat.yMMMMd('it').format(date)),
        children: (snap['results'])
            .map((r) => parseRawResult(r))
            .where((e) => e != null)
            .map((e) => ListTile(
                  leading: Text(e.key),
                  title: Text(Tipologia.corsaDist.targetFormatter(e.value)),
                  trailing: Text(
                      'pb: ${Tipologia.corsaDist.targetFormatter(ResultsRouteList.pbs[e.key])}' +
                          ((ResultsRouteList.sbs[e.key] == null)
                              ? ''
                              : '\nsb: ${Tipologia.corsaDist.targetFormatter(ResultsRouteList.sbs[e.key])}')),
                ))
            .toList()
            .cast<Widget>(),
      );
}
