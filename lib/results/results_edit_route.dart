import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/athlete/results/results_route.dart';
import 'package:atletica/global_widgets/custom_dismissible.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/global_widgets/leading_info_widget.dart';
import 'package:atletica/main.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:atletica/refactoring/utils/singular_plural.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/results/results.dart';
import 'package:atletica/results/results_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

class ResultsEditRoute extends StatelessWidget {
  final Results results;
  ResultsEditRoute(this.results);

  final ScrollController horizontal = ScrollController();
  final ScrollController vertical = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RISULTATI'),
      ),
      body: ListView(
        children: results.results.keys
            .map((a) => StreamBuilder<Result>(
                stream: a.resultsStream(date: results.date),
                initialData: a.resultsOf(results.date).firstWhereNullable(
                    (r) => r.isCompatible(results.training)),
                builder: (context, snapshot) {
                  if (snapshot.hasData) results.update(a, snapshot.data!);

                  final int count = results.results[a]!.results.values
                      .where((v) => v != null)
                      .length;

                  final Athlete athlete = a;
                  final Result res = results.results[a]!;
                  return CustomDismissible(
                    key: ValueKey(Object.hashAll([results, a])),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) {
                      showResultsEditDialog(
                        context,
                        results.results[a]!,
                        (r) => Globals.coach.saveResult(athlete: a, results: r),
                      );
                      return Future.value(false);
                    },
                    child: CustomExpansionTile(
                      title: athlete.name,
                      leading: Icon(
                        res.fatigue == null
                            ? Mdi.emoticonNeutralOutline
                            : icons[res.fatigue!],
                        size: 42,
                        color: res.fatigue == null
                            ? Theme.of(context).disabledColor
                            : Color.lerp(Colors.green, Colors.red,
                                res.fatigue! / icons.length),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.compare_arrows),
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ResultsRouteList(athlete, res.training),
                                )),
                          ),
                          LeadingInfoWidget(
                            info: '$count/${results.ripetuteCount}',
                            bottom: singPlurIT('risultato', count),
                          ),
                        ],
                      ),
                      hiddenSubtitle: res.info,
                      children: res.asIterable
                          .map((e) => CustomListTile(
                                title: Text(e.key.name,
                                    textAlign: TextAlign.center),
                                leading: Text(
                                  e.value == null
                                      ? 'N.P.'
                                      : Tipologia.corsaDist
                                          .formatTarget(e.value),
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                                trailing: RichText(
                                  text: TextSpan(
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                      children: [
                                        TextSpan(
                                          text: 'PB: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal),
                                        ),
                                        TextSpan(
                                          text: Tipologia.corsaDist
                                              .formatTarget(
                                                  athlete.pb(e.key.name)),
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColorDark),
                                        ),
                                        if (athlete.tb(res.uniqueIdentifier,
                                                e.key.name) !=
                                            null)
                                          TextSpan(
                                            text: '\nTB: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.normal),
                                          ),
                                        if (athlete.tb(res.uniqueIdentifier,
                                                e.key.name) !=
                                            null)
                                          TextSpan(
                                            text: Tipologia.corsaDist
                                                .formatTarget(
                                              athlete.tb(res.uniqueIdentifier,
                                                  e.key.name),
                                            ),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                            ),
                                          ),
                                      ]),
                                ),
                              ))
                          .toList()
                          .cast<Widget>(),
                    ),
                  );
                }))
            .toList(),
      ),
    );
  }
}
