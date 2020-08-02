import 'package:Atletica/athlete/results/results_route.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/global_widgets/custom_list_tile.dart';
import 'package:Atletica/ripetuta/template.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

MapEntry<String, double> parseRawResult(String rawResult) {
  if (rawResult == null) return null;
  final List<String> splitted = rawResult.split(':');
  if (splitted.length != 2) return null;
  if (splitted[0].isEmpty || splitted[1].isEmpty) return null;
  final double value = double.tryParse(splitted[1]);
  if (value == null) return null;
  return MapEntry<String,double>(splitted[0], value);
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
        subtitle: Text(
          DateFormat.yMMMMd('it').format(date),
          style: TextStyle(color: Theme.of(context).primaryColorDark),
        ),
        children: (snap['results'])
            .map((r) => parseRawResult(r))
            .where((e) => e != null)
            .map((e) => CustomListTile(
                  title: Text(e.key),
                  subtitle: Text(
                    Tipologia.corsaDist.targetFormatter(e.value),
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                  trailing: RichText(
                    text: TextSpan(
                        style: Theme.of(context).textTheme.overline,
                        children: [
                          TextSpan(
                              text: 'pb: ',
                              style: TextStyle(fontWeight: FontWeight.normal)),
                          TextSpan(
                              text: Tipologia.corsaDist
                                  .targetFormatter(ResultsRouteList.pbs[e.key]),
                              style: TextStyle(
                                  color: Theme.of(context).primaryColorDark)),
                          if (ResultsRouteList.sbs[e.key] != null)
                            TextSpan(
                                text: '\nsb: ',
                                style:
                                    TextStyle(fontWeight: FontWeight.normal)),
                          if (ResultsRouteList.sbs[e.key] != null)
                            TextSpan(
                                text: Tipologia.corsaDist.targetFormatter(
                                    ResultsRouteList.sbs[e.key]),
                                style: TextStyle(
                                    color: Theme.of(context).primaryColorDark)),
                        ]),
                  ),
                ))
            .toList()
            .cast<Widget>(),
      );
}
