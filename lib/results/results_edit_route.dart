import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/custom_list_tile.dart';
import 'package:Atletica/global_widgets/leading_info_widget.dart';
import 'package:Atletica/main.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/results/result.dart';
import 'package:Atletica/results/results_edit_dialog.dart';
import 'package:flutter/material.dart';

class ResultsEditRoute extends StatelessWidget {
  final Result results;
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
            .map((a) => StreamBuilder(
                stream: userC.resultSnapshots(
                  athlete: userC.rawAthletes[a],
                  dateIdentifier: _dateIdentifierFormatter(
                      results.training.training.date.dateTime),
                ),
                builder: (context, snapshot) {
                  bool ok = true;
                  if (snapshot.data?.data != null) {
                    ok = results.update(
                        a, snapshot.data['results'].cast<String>());
                  }

                  if (!ok) return Container();

                  final int count =
                      results.results[a].values.where((v) => v != null).length;

                  return CustomDismissible(
                    key: ValueKey(hashList([results, a])),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) {
                      showResultsEditDialog(
                        context,
                        results.results[a],
                        (r) => userC.saveResult(
                          athlete: a,
                          dateIdentifier: _dateIdentifierFormatter(),
                          results: r,
                          training: results.training.name,
                        ),
                      );
                      return Future.value(false);
                    },
                    child: CustomListTile(
                      title: Text(userC.rawAthletes[a].name),
                      trailing: LeadingInfoWidget(
                        info: '$count/${results.ripetuteCount}',
                        bottom: singularPlural('risultat', 'o', 'i', count),
                      ),
                    ),
                  );
                }))
            .toList(),
      ),
    );
  }
}

String _dateIdentifierFormatter([DateTime date]) {
  date ??= DateTime.now();
  date = date.toUtc();
  return date.year.toString() +
      date.month.toString().padLeft(2, '0') +
      date.day.toString().padLeft(2, '0');
}
