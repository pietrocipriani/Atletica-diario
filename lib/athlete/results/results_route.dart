import 'dart:math';

import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/results/result_widget.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/results/result.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResultsRouteList extends StatelessWidget {
  final Athlete athlete;
  final Map<DocumentReference, Result> results = {};

  static final Map<String, double> pbs = {};

  /// `tbs`: training bests
  ///
  /// the key of the Map is the `':'` concatenation of the `Result.ripetute` iterable
  ///
  /// the key of the inner Map is `SimpleRipetuta.name`
  /// and the value is the corrispective double value to format
  static final Map<String, Map<String, double>> tbs = {};

  ResultsRouteList(this.athlete);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RISULTATI di ${athlete.name}'),
      ),
      body: StreamBuilder(
        stream: userC.resultSnapshots(athlete: athlete),
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            for (DocumentChange doc in snapshot.data.documentChanges) {
              switch (doc.type) {
                case DocumentChangeType.added:
                case DocumentChangeType.modified:
                  if (doc.document['results'].any((l) => !l.endsWith('null')))
                    results[doc.document.reference] = Result(doc.document);
                  break;
                case DocumentChangeType.removed:
                  results.remove(doc.document.reference);
                  break;
              }
            }
            tbs.clear();
            pbs.clear();
            for (final DocumentSnapshot snap in snapshot.data.documents) {
              final Result result = Result(snap);
              final String identifier = result.uniqueIdentifier;
              for (final MapEntry<SimpleRipetuta, double> e
                  in result.asIterable) {
                if (e.value == null) continue;
                pbs[e.key.name] = min(
                  e.value,
                  pbs[e.key.name] ?? double.infinity,
                );
                final Map<String, double> map =
                    tbs[identifier] ??= <String, double>{};
                map[e.key.name] = min(
                  e.value,
                  map[e.key.name] ?? double.infinity,
                );
              }
            }
          }

          return ListView(
            children: results.values.map((res) => ResultWidget(res)).toList(),
          );
        },
      ),
    );
  }
}
