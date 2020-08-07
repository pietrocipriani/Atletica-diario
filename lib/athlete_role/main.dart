import 'package:Atletica/athlete_role/request_coach.dart';
import 'package:Atletica/athlete_role/result.dart';
import 'package:Atletica/date.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/athlete_helper.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:Atletica/training/allenamento.dart';
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
    final Allenamento a = s.work;
    if (a == null) return Container();
    return CustomExpansionTile(
      title: a.name,
      titleColor: s == compatible || compatible == null
          ? Colors.black
          : Colors.grey[300],
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() <= s.date && (s == compatible || compatible == null) ? () {} : null,
        /*onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsEditRoute(
                Result(
                  training: SimpleTraining.from(s),
                  athletes: userC.athletes.map((a) => a.reference),
                ),
              ),
            )),*/
        color: Colors.black,
        disabledColor: Colors.grey[300],
      ),
      leading: Radio<ScheduledTraining>(
        value: s,
        groupValue: compatible,
        onChanged: (st) {
          print('called with arg: $st');
          userA.saveResult(
            date: Date.fromDateTime(controller.selectedDay),
            results: Map<SimpleRipetuta, double>.fromIterable(
              st.work.ripetute.map((r) => SimpleRipetuta.from(r)),
              key: (r) => r,
              value: (r) => null,
            ),
            training: st.work.name,
          );
        },
      ),
      children: a.ripetuteAsDescription(context).toList(),
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

    for (final ScheduledTraining st in userA.events[controller.selectedDay])
      if (result.isCompatible(st)) return st;

    // TODO: distinguish between missing and incompatible result
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
          Expanded(
            child: ListView(
              children: userA.events[controller.selectedDay]
                      ?.map((st) => _trainingWidget(st, compatibleST))
                      ?.toList() ??
                  [],
            ),
          ),
        ],
      ),
    );
  }
}
