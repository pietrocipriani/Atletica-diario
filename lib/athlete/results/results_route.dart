import 'dart:math';

import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/results/result_widget.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResultsRouteList extends StatelessWidget {
  final Athlete athlete;
  final Map<DocumentReference, ResultWidget> results = {};

  static final Map<String, double> pbs = {}, sbs = {};

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
                  results[doc.document.reference] = ResultWidget(doc.document);
                  break;
                case DocumentChangeType.removed:
                  results.remove(doc.document.reference);
                  break;
              }
            }
            sbs.clear();
            pbs.clear();
            for (DocumentSnapshot snap in snapshot.data.documents) {
              snap['results']
                  .map((r) => parseRawResult(r))
                  .where((e) => e != null)
                  .forEach((e) {
                pbs[e.key] = min(e.value, pbs[e.key] ?? double.infinity);
                if (DateTime.now()
                        .difference(DateTime.parse(snap.documentID))
                        .inDays >
                    365) return;
                sbs[e.key] = min(e.value, sbs[e.key] ?? double.infinity);
              });
            }
          }

          return ListView(
            children: results.values.toList(),
          );
        },
      ),
    );
  }
}
