import 'package:atletica/athlete/athletes_route.dart';
import 'package:atletica/date.dart';
import 'package:atletica/global_widgets/logout_button.dart';
import 'package:atletica/global_widgets/swap_button.dart';
import 'package:atletica/home/home_page.dart';
import 'package:atletica/main.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/plan/widgets/plans_route.dart';
import 'package:atletica/schedule/schedule_dialogs/scheduled_training_dialog.dart';
import 'package:atletica/training/widgets/training_route.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

class CoachMainPage extends StatefulWidget {
  @override
  _CoachMainPageState createState() => _CoachMainPageState();
}

class _CoachMainPageState extends State<CoachMainPage> {
  DateTime selectedDay;

  bool get _canAddEvents {
    if (selectedDay == null) return false;
    return (Date.now() - selectedDay).inDays < 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atletica - Allenatore'),
        actions: [LogoutButton(context: context), SwapButton(context: context)],
      ),
      body: HomePageWidget(onSelectedDayChanged: (day) {
        selectedDay = day;
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
      }),
      floatingActionButton: _canAddEvents
          ? FloatingActionButton(
              onPressed: () async {
                if (await showDialog<bool>(
                      context: context,
                      builder: (context) =>
                          ScheduledTrainingDialog(selectedDay),
                    ) ??
                    false) setState(() {});
              },
              child: Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _BottomAppBar(setState: setState),
    );
  }
}

class _BottomAppBar extends StatelessWidget {
  final void Function(void Function()) setState;

  _BottomAppBar({@required this.setState});

  Widget _sectionBtn({
    @required BuildContext context,
    @required IconData icon,
    @required Widget route,
    bool notify = false,
    bool onPop = false,
    String tooltip,
  }) {
    Widget iconWidget = Icon(icon, color: Colors.black);
    if (notify)
      iconWidget = Stack(
        alignment: Alignment.topRight,
        children: <Widget>[
          iconWidget,
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          )
        ],
      );
    return IconButton(
      tooltip: tooltip,
      icon: iconWidget,
      onPressed: () => startRoute(
        context: context,
        route: route,
        setState: onPop ? setState : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      child: Row(children: [
        /*_sectionBtn(
          context: context,
          icon: Icons.schedule,
          route: ScheduleRoute(),
          onPop: true,
          tooltip:
              'programma gli allenamenti per uno specifico gruppo di atleti',
        ),*/
        _sectionBtn(
            context: context,
            icon: Icons.directions_run,
            route: AthletesRoute(),
            notify: userC.requests.isNotEmpty,
            tooltip: 'gestisci i tuoi atleti'),
        _sectionBtn(
            context: context,
            icon: Mdi.table,
            route: PlansRoute(),
            tooltip: 'gestisci i programmi di lavoro'),
        _sectionBtn(
            context: context,
            icon: Icons.fitness_center,
            route: TrainingRoute(),
            tooltip: 'gestisci gli allenamenti'),
      ]),
      color: Theme.of(context).primaryColor,
    );
  }
}
