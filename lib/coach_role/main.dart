import 'package:AtleticaCoach/athlete/athletes_route.dart';
import 'package:AtleticaCoach/home/home_page.dart';
import 'package:AtleticaCoach/main.dart';
import 'package:AtleticaCoach/plan/tabella.dart';
import 'package:AtleticaCoach/schedule/schedule_route.dart';
import 'package:AtleticaCoach/training/allenamento.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

class CoachMainPage extends StatefulWidget {
  @override
  _CoachMainPageState createState() => _CoachMainPageState();
}

class _CoachMainPageState extends State<CoachMainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atletica - Allenatore'),
      ),
      body: HomePageWidget(),
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
    if (notify) iconWidget = Stack(
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
      child: Row(children: [
        _sectionBtn(
          context: context,
          icon: Icons.schedule,
          route: ScheduleRoute(),
          onPop: true,
          tooltip:
              'programma gli allenamenti per uno specifico gruppo di atleti',
        ),
        _sectionBtn(
            context: context,
            icon: Icons.directions_run,
            route: AthletesRoute(),
            //notify: user?.requests?.isNotEmpty ?? false,
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
