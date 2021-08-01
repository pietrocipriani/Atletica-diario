import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/athlete/athletes_route.dart';
import 'package:atletica/date.dart';
import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/global_widgets/logout_button.dart';
import 'package:atletica/global_widgets/runas_button.dart';
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
  DateTime? selectedDay;

  bool get _canAddEvents {
    if (selectedDay == null) return false;
    return (Date.now() - selectedDay).inDays < 7;
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> actions = [
      LogoutButton(context: context),
      SwapButton(context: context),
      if (user.admin) RunasButton(context: context),
    ];

    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.landscape)
        actions.addAll(_BottomAppBar.children(
          context: context,
          setState: null,
          onPrimary: false,
        ));
      return Scaffold(
        appBar: orientation == Orientation.portrait
            ? AppBar(
                title: Text('Atletica - Allenatore'),
                actions: actions.cast(),
              )
            : null,
        body: HomePageWidget(
          onSelectedDayChanged: (day) {
            selectedDay = day;
            WidgetsBinding.instance!
                .addPostFrameCallback((_) => setState(() {}));
          },
          orientation: orientation,
        ),
        floatingActionButton: _canAddEvents
            ? FloatingActionButton(
                onPressed: () async {
                  if (await showDialog<bool>(
                        context: context,
                        builder: (context) =>
                            ScheduledTrainingDialog(selectedDay!),
                      ) ??
                      false) setState(() {});
                },
                child: Icon(Icons.add),
              )
            : null,
        drawer: orientation == Orientation.landscape
            ? Drawer(
                child: Padding(
                  padding: MediaQuery.of(context).padding,
                  child: Column(
                      children: actions
                          .map((action) => CustomListTile(
                                leading: action,
                                title: Text(action.tooltip ?? ''),
                                onTap: action.onPressed,
                              ))
                          .toList()),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: orientation == Orientation.portrait
            ? _BottomAppBar(setState: setState)
            : null,
      );
    });
  }
}

class _BottomAppBar extends StatelessWidget {
  final void Function(void Function()) setState;

  _BottomAppBar({required this.setState});

  static List<SectionBtn> children({
    required final BuildContext context,
    required void Function(void Function())? setState,
    bool onPrimary = true,
  }) =>
      [
        /*_sectionBtn(
          context: context,
          icon: Icons.schedule,
          route: ScheduleRoute(),
          onPop: true,
          tooltip:
              'programma gli allenamenti per uno specifico gruppo di atleti',
        ),*/
        SectionBtn(
          icon: Icons.directions_run,
          route: AthletesRoute(),
          setState: setState,
          notify: Athlete.hasRequests,
          tooltip: 'ATLETI',
          onPrimary: onPrimary,
        ),
        SectionBtn(
          icon: Mdi.table,
          route: PlansRoute(),
          setState: setState,
          tooltip: 'PIANI DI LAVORO',
          onPrimary: onPrimary,
        ),
        SectionBtn(
          icon: Icons.fitness_center,
          route: TrainingRoute(),
          setState: setState,
          tooltip: 'ALLENAMENTI',
          onPrimary: onPrimary,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      child: Row(children: children(context: context, setState: setState)),
      color: Theme.of(context).primaryColor,
    );
  }
}

class SectionBtn extends StatelessWidget {
  final Function(void Function())? setState;
  final IconData icon;
  final Widget route;
  final bool notify;
  final bool onPop;
  final String? tooltip;
  final bool onPrimary;

  const SectionBtn({
    required this.setState,
    required this.icon,
    required this.route,
    this.notify = false,
    this.onPop = false,
    this.tooltip,
    this.onPrimary: true,
  });

  @override
  Widget build(final BuildContext context) {
    Widget iconWidget = Icon(
      icon,
      color: onPrimary
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onSurface,
    );
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
}
