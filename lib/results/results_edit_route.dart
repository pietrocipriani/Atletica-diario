import 'package:Atletica/main.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/results/result.dart';
import 'package:Atletica/results/results_edit_dialog.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResultsEditRoute extends StatelessWidget {
  final Result results;
  ResultsEditRoute(this.results);

  final ScrollController horizontal = ScrollController();
  final ScrollController vertical = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: results.results.keys
            .map((a) => ListTile(
                  title: Text(userC.rawAthletes[a].name),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => showResultsEditDialog(
                      context,
                      results.results[a],
                      (r) => userC.saveResult(
                        athlete: a,
                        dateIdentifier: _dateIdentifierFormatter(),
                        results: r,
                      ),
                    ),
                  ),
                  leading: StreamBuilder<DocumentSnapshot>(
                    stream: userC.resultSnapshots(
                      athlete: a,
                      dateIdentifier: _dateIdentifierFormatter(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.data?.data != null) {
                        final Map<String, dynamic> data = snapshot.data.data;
                        data.entries.forEach((r) {
                          final int index = int.tryParse(r.key.substring(0, 3));
                          if (index == null ||
                              index < 0 ||
                              index >= results.training.ripetute.length) return;
                          final String name = r.key.substring(3);
                          final SimpleRipetuta rip =
                              results.training.ripetute[index];
                          if (rip.name != name) return;
                          results.results[a][rip] = r.value;
                        });
                      }
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            '${snapshot.data == null ? 0 : snapshot.data.data.entries.where((e) => e.value != null).length}/${results.ripetuteCount}',
                            style: Theme.of(context).textTheme.headline5,
                          ),
                          Text(
                            singularPlural('risultat', 'o', 'i', 0),
                            style: Theme.of(context).textTheme.overline,
                          )
                        ],
                      );
                    },
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
