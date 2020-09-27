import 'package:Atletica/athlete_role/request_coach.dart';
import 'package:Atletica/results/result.dart';
import 'package:Atletica/date.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/athlete_helper.dart';
import 'package:Atletica/results/results_edit_dialog.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/training/training_description.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';
import 'package:table_calendar/table_calendar.dart';

class AthleteMainPage extends StatefulWidget {
  @override
  _AthleteMainPageState createState() => _AthleteMainPageState();
}

class _AthleteMainPageState extends State<AthleteMainPage> {
  final CalendarController controller = CalendarController();
  final Callback _callback = Callback();

  @override
  void initState() {
    AthleteHelper.onResultCallbacks.add(_callback..f = (v) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    AthleteHelper.onResultCallbacks.remove(_callback.stopListening);
    super.dispose();
  }

  Widget _trainingWidget(
      final ScheduledTraining s, final ScheduledTraining compatible) {
    final Result result = compatible == null
        ? null
        : userA.getResult(Date.fromDateTime(controller.selectedDay));
    final Allenamento a = s.work;
    print ({0: 't', 1: 'e', 2: 's', 3:'t'}.entries.map((e) => e.value));
    if (a == null) return Container();
    print('no container!');
    final bool greyed = s != compatible && compatible != null;

    return CustomExpansionTile(
      title: a.name,
      titleColor: !greyed ? Colors.black : Colors.grey[300],
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() >= s.date && !greyed
            ? () => showResultsEditDialog(
                  context,
                  result ?? Result.empty(a, s.date),
                  (r) => userA.saveResult(results: r),
                )
            : null,
        color: Colors.black,
        disabledColor: Colors.grey[300],
      ),
      leading: Radio<ScheduledTraining>(
        value: s,
        groupValue: compatible,
        onChanged: (st) {
          userA.saveResult(
            results: Result.empty(
              st.work,
              Date.fromDateTime(controller.selectedDay),
            ),
          );
        },
      ),
      children:
          TrainingDescription.fromTraining(context, a, result, greyed).toList(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40),
    );
  }

  Widget _resultWidget(final Result result) {
    if (result?.training == null) return Container();
    return CustomExpansionTile(
      title: '${result.training} (prev)',
      titleColor: Colors.black,
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() >= result.date
            ? () => showResultsEditDialog(
                  context,
                  result,
                  (r) => userA.saveResult(results: r),
                )
            : null,
        color: Colors.black,
        disabledColor: Colors.grey[300],
      ),
      leading: Radio<ScheduledTraining>(
        value: null,
        groupValue: null,
        onChanged: (st) {},
      ),
      children: TrainingDescription.fromResults(context, result).toList(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40),
      /*trailing: IconButton(
        icon: Icon(Icons.play_arrow),
        onPressed: () {},
        color: Colors.black,
      ),*/
    );
  }

  ScheduledTraining get _compatibleST {
    if (controller.selectedDay == null) return null;
    final Result result =
        userA.getResult(Date.fromDateTime(controller.selectedDay));
    if (result == null) return null;
    if (userA.events[controller.selectedDay] == null) return null;

    for (final ScheduledTraining st in userA.events[controller.selectedDay])
      if (result.isCompatible(st)) return st;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!userA.hasCoach)
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RequestCoachRoute()),
        ),
      );
    final ScheduledTraining compatibleST = _compatibleST;
    final Result result = controller.selectedDay == null
        ? null
        : userA.getResult(Date.fromDateTime(controller.selectedDay));
    List<Widget> children = <Widget>[
      if (result != null && compatibleST == null) _resultWidget(result)
    ];
    if (userA.events[controller.selectedDay] != null)
      children = children
          .followedBy(userA.events[controller.selectedDay]
              ?.where((st) =>
                  st == compatibleST ||
                  st.athletes.isEmpty ||
                  st.athletes.contains(userA.athleteCoachReference))
              ?.map((st) => _trainingWidget(st, compatibleST)))
          .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Atletica - Atleta')),
      body: Column(
        children: [
          TableCalendar(
            calendarController: controller,
            availableCalendarFormats: {
              CalendarFormat.month: 'mese',
              CalendarFormat.week: 'settimana'
            },
            calendarStyle: CalendarStyle(
              selectedColor: Theme.of(context).primaryColor,
              todayColor: Theme.of(context).primaryColorLight,
              markersColor: Theme.of(context).primaryColorDark,
              todayStyle: const TextStyle(color: Colors.black),
              outsideStyle: TextStyle(color: Colors.grey[300]),
              outsideWeekendStyle: TextStyle(color: Colors.red[100]),
            ),
            locale: 'it',
            startingDayOfWeek: StartingDayOfWeek.monday,
            weekendDays: [DateTime.sunday],
            headerStyle: HeaderStyle(
              formatButtonShowsNext: false,
              formatButtonVisible: false,
              centerHeaderTitle: true,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: Theme.of(context).textTheme.overline,
              weekendStyle: Theme.of(context).textTheme.overline,
            ),
            events: userA.events,
            onDaySelected: (d, evts) => setState(() {}),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            height: 1,
            color: Colors.grey[300],
          ),
          Expanded(child: ListView(children: children)),
        ],
      ),
    );
  }
}
