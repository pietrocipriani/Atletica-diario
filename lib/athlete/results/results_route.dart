import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/results/result_widget.dart';
import 'package:flutter/material.dart';

class ResultsRouteList extends StatelessWidget {
  final Athlete athlete;

  ResultsRouteList(this.athlete);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RISULTATI di ${athlete.name}'),
      ),
      body: ListView(
        children: athlete.results.values
            .map((res) => ResultWidget(res, athlete))
            .toList(),
      ),
    );
  }
}
