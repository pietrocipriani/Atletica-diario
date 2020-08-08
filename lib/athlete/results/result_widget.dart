import 'package:Atletica/athlete/results/results_route.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/global_widgets/custom_list_tile.dart';
import 'package:Atletica/results/result.dart';
import 'package:Atletica/ripetuta/template.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

MapEntry<String, double> parseRawResult(String rawResult) {
  if (rawResult == null) return null;
  final List<String> splitted = rawResult.split(':');
  if (splitted.length != 2) return null;
  if (splitted[0].isEmpty || splitted[1].isEmpty) return null;
  final double value =
      splitted[1] == 'null' ? null : double.tryParse(splitted[1]) ?? -1;
  if ((value ?? 1) < 0) return null;
  return MapEntry<String, double>(splitted[0], value);
}

class ResultWidget extends StatelessWidget {
  final Result res;

  ResultWidget(this.res);

  @override
  Widget build(BuildContext context) => CustomExpansionTile(
        title: res.training,
        subtitle: Text(
          DateFormat.yMMMMd('it').format(res.date.dateTime),
          style: TextStyle(color: Theme.of(context).primaryColorDark),
        ),
        childrenBackgroudColor: Theme.of(context).primaryColor,
        childrenPadding: const EdgeInsets.all(8),
        children: res.asIterable
            .map((e) => CustomListTile(
                  title: Text(e.key.name, textAlign: TextAlign.center),
                  leading: Text(
                    e.value == null
                        ? 'N.P.'
                        : Tipologia.corsaDist.targetFormatter(e.value),
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  tileColor: Theme.of(context).scaffoldBackgroundColor,
                  trailing: RichText(
                    text: TextSpan(
                        style: Theme.of(context).textTheme.overline,
                        children: [
                          TextSpan(
                            text: 'PB: ',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                          TextSpan(
                            text: Tipologia.corsaDist.targetFormatter(
                                ResultsRouteList.pbs[e.key.name]),
                            style: TextStyle(
                                color: Theme.of(context).primaryColorDark),
                          ),
                          if (ResultsRouteList.tbs[res.uniqueIdentifier]
                                  [e.key.name] !=
                              null)
                            TextSpan(
                              text: '\nTB: ',
                              style: TextStyle(fontWeight: FontWeight.normal),
                            ),
                          if (ResultsRouteList.tbs[res.uniqueIdentifier]
                                  [e.key.name] !=
                              null)
                            TextSpan(
                              text: Tipologia.corsaDist.targetFormatter(
                                ResultsRouteList.tbs[res.uniqueIdentifier]
                                    [e.key.name],
                              ),
                              style: TextStyle(
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                        ]),
                  ),
                ))
            .toList()
            .cast<Widget>(),
      );
}
