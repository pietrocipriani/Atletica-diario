import 'package:Atletica/athlete_role/request_coach.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/athlete_helper.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AthleteMainPage extends StatefulWidget {

  @override
  _AthleteMainPageState createState() => _AthleteMainPageState();
}

class _AthleteMainPageState extends State<AthleteMainPage> {
  final CalendarController controller = CalendarController();
  final Callback _callback = Callback();

  @override
  void initState () {
    AthleteHelper.onResultCallbacks.add(_callback..f = (v) => setState);
    super.initState();
  }

  @override
  void dispose () {
    AthleteHelper.onResultCallbacks.remove(_callback.stopListening);
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(title: Text('Atletica - Atleta')),
      body: TableCalendar(
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
        headerStyle: HeaderStyle(formatButtonShowsNext: false),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: Theme.of(context).textTheme.overline,
          weekendStyle: Theme.of(context).textTheme.overline,
        ),
        events: userA.events,
      ),
    );
  }
}
