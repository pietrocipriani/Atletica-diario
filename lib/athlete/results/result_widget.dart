import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/results/results_edit_dialog.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdi/mdi.dart';

MapEntry<String, double?>? parseRawResult(String? rawResult) {
  if (rawResult == null) return null;
  final List<String> splitted = rawResult.split(':');
  if (splitted.length != 2) return null;
  if (splitted[0].isEmpty || splitted[1].isEmpty) return null;
  final double? value =
      splitted[1] == 'null' ? null : double.tryParse(splitted[1]) ?? -1;
  if ((value ?? 1) < 0) return null;
  return MapEntry<String, double?>(splitted[0], value);
}

class ResultWidget extends StatelessWidget {
  final Result res;
  final Athlete athlete;
  final void Function(String)? onFilter;

  ResultWidget(this.res, this.athlete, {this.onFilter});

  @override
  Widget build(BuildContext context) => CustomExpansionTile(
        title: res.training,
        subtitle: Text(
          DateFormat.yMMMMd('it').format(res.date),
          style: TextStyle(color: Theme.of(context).primaryColorDark),
        ),
        hiddenSubtitle: res.info,
        leading: Icon(
          res.fatigue == null
              ? Mdi.emoticonNeutralOutline
              : icons[res.fatigue!],
          size: 42,
          color: res.fatigue == null
              ? Theme.of(context).disabledColor
              : Color.lerp(
                  Colors.green, Colors.red, res.fatigue! / icons.length),
        ),
        trailing: onFilter == null
            ? null
            : IconButton(
                icon: Icon(Icons.filter_alt),
                onPressed: () => onFilter!(res.training),
              ),
        children: res.asIterable
            .map((e) => CustomListTile(
                  title: Text(e.key.name, textAlign: TextAlign.center),
                  leading: Text(
                    e.value == null
                        ? 'N.P.'
                        : Tipologia.corsaDist.targetFormatter(e.value),
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  trailing: RichText(
                    text: TextSpan(
                        style: Theme.of(context).textTheme.overline,
                        children: [
                          TextSpan(
                            text: 'PB: ',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                          TextSpan(
                            text: Tipologia.corsaDist
                                .targetFormatter(athlete.pb(e.key.name)),
                            style: TextStyle(
                                color: Theme.of(context).primaryColorDark),
                          ),
                          if (athlete.tb(res.uniqueIdentifier, e.key.name) !=
                              null)
                            TextSpan(
                              text: '\nTB: ',
                              style: TextStyle(fontWeight: FontWeight.normal),
                            ),
                          if (athlete.tb(res.uniqueIdentifier, e.key.name) !=
                              null)
                            TextSpan(
                              text: Tipologia.corsaDist.targetFormatter(
                                athlete.tb(res.uniqueIdentifier, e.key.name),
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
