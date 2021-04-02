/*import 'package:atletica/athlete/athletes_route.dart';
import 'package:atletica/main.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/user_helper/coach_helper.dart';
import 'package:atletica/running_training/running_training.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/schedule/schedule_dialogs/schedule_dialog.dart';
import 'package:flutter/material.dart';

class ScheduleRoute extends StatefulWidget {
  @override
  _ScheduleRouteState createState() => _ScheduleRouteState();
}

final AppBar _appBar = AppBar(title: Text('PROGRAMMI'));

class _ScheduleRouteState extends State<ScheduleRoute> {
  GlobalKey<ScaffoldState> _scaffold = GlobalKey();

  final Callback callback = Callback();

  @override
  void initState() {
    callback.f = (_) => setState(() {});
    CoachHelper.onSchedulesCallbacks.add(callback);
    super.initState();
  }

  @override
  void dispose() {
    CoachHelper.onSchedulesCallbacks.remove(callback.stopListening);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffold,
      appBar: _appBar,
      body: schedules.values.any((s) => s.isValid)
          ? Column(
              children:
                  avaiableSchedules.map((schedule) => schedule.widget).toList(),
            )
          : Center(child: Text('nessun allenamento creato')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (userC.athletes.isEmpty)
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
}*/
