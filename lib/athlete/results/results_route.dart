import 'package:atletica/athlete/atleta.dart';
import 'package:atletica/athlete/results/result_widget.dart';
import 'package:atletica/results/pbs/pbs_page_route.dart';
import 'package:flutter/material.dart';

class ResultsRouteList extends StatefulWidget {
  final Athlete athlete;

  ResultsRouteList(this.athlete);

  @override
  _ResultsRouteListState createState() => _ResultsRouteListState();
}

class _ResultsRouteListState extends State<ResultsRouteList>
    with SingleTickerProviderStateMixin {
  TabController _controller;

  @override
  void initState() {
    _controller = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RISULTATI di ${widget.athlete.name}'),
        bottom: TabBar(
          controller: _controller,
          tabs: [
            Tab(text: 'RISULTATI'),
            Tab(text: 'PERSONALI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          ListView(
            children: widget.athlete.results.values
                .map((res) => ResultWidget(res, widget.athlete))
                .toList(),
          ),
          PbsWidget(res: widget.athlete.results.values, clear: true)
        ],
      ),
    );
  }
}
