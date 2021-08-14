import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/athlete/results/result_widget.dart';
import 'package:atletica/results/pbs/pbs_page_route.dart';
import 'package:flutter/material.dart';

class ResultsRouteList extends StatefulWidget {
  final Athlete athlete;
  final String? filter;

  ResultsRouteList(this.athlete, [this.filter]);

  @override
  _ResultsRouteListState createState() => _ResultsRouteListState();
}

class _ResultsRouteListState extends State<ResultsRouteList>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 2, vsync: this);
  late String? filter = widget.filter;

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
            children: widget.athlete.results
                .where((res) =>
                    !res.isBooking &&
                    (filter == null || res.training == filter))
                .map((res) => ResultWidget(
                      res,
                      widget.athlete,
                      onFilter: (f) =>
                          setState(() => filter = filter == f ? null : f),
                    ))
                .toList(),
          ),
          PbsWidget(res: widget.athlete.results, clear: true)
        ],
      ),
    );
  }
}
