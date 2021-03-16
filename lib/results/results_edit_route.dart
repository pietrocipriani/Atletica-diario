import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/global_widgets/custom_list_tile.dart';
import 'package:Atletica/global_widgets/leading_info_widget.dart';
import 'package:Atletica/main.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/results/result.dart';
import 'package:Atletica/results/results.dart';
import 'package:Atletica/results/results_edit_dialog.dart';
import 'package:Atletica/ripetuta/template.dart';
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
            .where((a) => userC.rawAthletes.containsKey(a))
            .map((a) => StreamBuilder(
                stream: userC.resultSnapshots(
                  athlete: userC.rawAthletes[a],
                  dateIdentifier: results.date.formattedAsIdentifier,
                ),
                builder: (context, snapshot) {
                  bool ok = true;
                  if (snapshot.data?.data != null) {
                    ok = results.update(
                        a,
                        snapshot.data['results'].cast<String>(),
                        snapshot.data['fatigue']);
                  }

                  if (!ok) return Container();

                  final int count = results.results[a].results.values
                      .where((v) => v != null)
                      .length;

                  final Athlete athlete = userC.rawAthletes[a];
                  final Result res = results.results[a];
                  return CustomDismissible(
                    key: ValueKey(hashList([results, a])),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) {
                      showResultsEditDialog(
                        context,
                        results.results[a],
                        (r) => userC.saveResult(athlete: a, results: r),
                      );
                      return Future.value(false);
                    },
                    child: CustomExpansionTile(
                      title: userC.rawAthletes[a].name,
                      leading: Icon(
                        results.results[a].fatigue == null
                            ? Mdi.emoticonNeutralOutline
                            : icons[results.results[a].fatigue],
                        size: 42,
                        color: results.results[a].fatigue == null
                            ? Colors.grey[300]
                            : Color.lerp(Colors.green, Colors.red,
                                results.results[a].fatigue / icons.length),
                      ),
                      trailing: LeadingInfoWidget(
                        info: '$count/${results.ripetuteCount}',
                        bottom: singularPlural('risultat', 'o', 'i', count),
                      ),
                      childrenBackgroudColor: Theme.of(context).primaryColor,
                      childrenPadding: const EdgeInsets.all(8),
                      children: res.asIterable
                          .map((e) => CustomListTile(
                                title: Text(e.key.name,
                                    textAlign: TextAlign.center),
                                leading: Text(
                                  e.value == null
                                      ? 'N.P.'
                                      : Tipologia.corsaDist
                                          .targetFormatter(e.value),
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                                tileColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                trailing: RichText(
                                  text: TextSpan(
                                      style:
                                          Theme.of(context).textTheme.overline,
                                      children: [
                                        TextSpan(
                                          text: 'PB: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal),
                                        ),
                                        TextSpan(
                                          text: Tipologia.corsaDist
                                              .targetFormatter(
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
                                                .targetFormatter(
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
