import 'package:Atletica/schedule/schedule.dart';
import 'package:Atletica/schedule/schedule_widgets/schedule_widget.dart';
import 'package:flutter/material.dart';

class ScheduleRoute extends StatefulWidget {
  @override
  _ScheduleRouteState createState() => _ScheduleRouteState();
}

final AppBar _appBar = AppBar(title: Text('PROGRAMMI'));

class _ScheduleRouteState extends State<ScheduleRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar,
      body: Column(
        children: schedules
            .map((schedule) => schedule.widget)
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await Schedule.fromDialog(context)) setState(() {});
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
