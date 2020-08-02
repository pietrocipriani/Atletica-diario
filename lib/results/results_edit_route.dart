import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/custom_list_tile.dart';
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
            .map((a) => CustomDismissible(
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
                    trailing: StreamBuilder(
                      stream: userC.resultSnapshots(
                        athlete: userC.rawAthletes[a],
                        dateIdentifier: _dateIdentifierFormatter(),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.data?.data != null) {
                          results.update(a, snapshot.data['results'].cast<String>());
                        }
                        final int count = results.results[a].values
                            .where((v) => v != null)
                            .length;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '$count/${results.ripetuteCount}',
                              style: Theme.of(context).textTheme.headline5,
                            ),
                            Text(
                              singularPlural('risultat', 'o', 'i', count),
                              style: Theme.of(context).textTheme.overline,
                            )
                          ],
                        );
                      },
                    ),
                  ),
                ))
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
