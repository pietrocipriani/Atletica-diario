import 'package:Atletica/athlete/results/result_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Result {
  final DateTime date;
  final String training;
  final Map<String, double> results;

  Result(DocumentSnapshot raw)
      : date = DateTime.parse(raw.documentID),
        training = raw['training'],
        results = Map.fromEntries(raw['results']
            .map<MapEntry<String, double>>((r) => parseRawResult(r)));
}
