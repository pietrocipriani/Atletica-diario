import 'package:Atletica/athlete/athletes_route.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/main.dart';
import 'package:Atletica/running_training/running_training.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:Atletica/schedule/schedule_dialogs/schedule_dialog.dart';
import 'package:flutter/material.dart';

class ScheduleRoute extends StatefulWidget {
  @override
  _ScheduleRouteState createState() => _ScheduleRouteState();
}

final AppBar _appBar = AppBar(title: Text('PROGRAMMI'));

class _ScheduleRouteState extends State<ScheduleRoute> {
  GlobalKey<ScaffoldState> _scaffold = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffold,
      appBar: _appBar,
      body: Column(
        children: schedules.map((schedule) => schedule.widget).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (groups.every((group) => group.atleti.isEmpty))
            _scaffold.currentState.showSnackBar(
              SnackBar(
                content: Text('nessun atleta disponibile'),
                action: SnackBarAction(
                  label: 'CREA',
                  onPressed: () => startRoute(
                    context: context,
                    route: AthletesRoute(),
                    setState: setState,
                  ),
                ),
                duration: Duration(seconds: 8),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
              ),
            );
          else if (await showScheduleDialog(context: context) ?? false) {
            updateFromSchedules();
            setState(() {});
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
