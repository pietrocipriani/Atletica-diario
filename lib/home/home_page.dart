import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:Atletica/results/results.dart';
import 'package:Atletica/results/results_edit_route.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/training/training_description.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

class HomePageWidget extends StatefulWidget {
  final void Function(DateTime day) onSelectedDayChanged;

  HomePageWidget({Key key, this.onSelectedDayChanged}) : super(key: key);

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final CalendarController _calendarController = CalendarController();

  final Callback callback = Callback();

  /// must listen `onAthleteCallbacks` because insertion/removal
  /// can change schedule's disponibility
  /// ```
  /// Iterable<Schedule> get avaiableSchedules =>
  ///   schedules.values.where((s) => s.athletes.isNotEmpty && s.isValid);
  /// ```
  @override
  void initState() {
    callback.f = (_) => setState(() {});
    CoachHelper.onSchedulesCallbacks.add(callback);

    CoachHelper.onAthleteCallbacks.add(callback);
    super.initState();
  }

  @override
  void dispose() {
    CoachHelper.onSchedulesCallbacks.remove(callback.stopListening);
    CoachHelper.onAthleteCallbacks.remove(callback);
    super.dispose();
  }

  Widget _trainingWidget(final ScheduledTraining s) {
    final Allenamento a = s.work;
    assert(a != null);
    return CustomExpansionTile(
      title: a.name,
      subtitle: s.athletes == null || s.athletes.isEmpty
          ? null
          : Text(
              s.athletesAsList,
              style: TextStyle(color: Theme.of(context).primaryColorDark),
            ),
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsEditRoute(
                Results(training: a, date: s.date),
              ),
            )),
        color: Colors.black,
      ),
      children: TrainingDescription.fromTraining(context, a).toList(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40),
      /*trailing: IconButton(
        icon: Icon(Icons.play_arrow),
        onPressed: () {},
        color: Colors.black,
      ),*/
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          calendarController: _calendarController,
          availableCalendarFormats: {
            CalendarFormat.month: 'mese',
            CalendarFormat.week: 'settimana'
          },
          locale: 'it',
          headerStyle: HeaderStyle(
            centerHeaderTitle: true,
            formatButtonVisible: false,
          ),
          calendarStyle: CalendarStyle(
            selectedColor: Theme.of(context).primaryColor,
            todayColor: Theme.of(context).primaryColorLight,
            markersColor: Theme.of(context).primaryColorDark,
            todayStyle: const TextStyle(color: Colors.black),
            outsideStyle: TextStyle(color: Colors.grey[300]),
            outsideWeekendStyle: TextStyle(color: Colors.red[100]),
          ),
          simpleSwipeConfig: const SimpleSwipeConfig(verticalThreshold: 15),
          startingDayOfWeek: StartingDayOfWeek.monday,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: Theme.of(context).textTheme.overline,
            weekendStyle: Theme.of(context).textTheme.overline,
          ),
          weekendDays: [DateTime.sunday],
          onDaySelected: (day, events) =>
              widget.onSelectedDayChanged?.call(day),
          onCalendarCreated: (first, last, format) => widget
              .onSelectedDayChanged
              ?.call(_calendarController.selectedDay),
          events: userC?.scheduledTrainings ?? {},
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          height: 1,
          color: Colors.grey[300],
        ),
        Expanded(
          child: ListView(
            children: userC.scheduledTrainings[_calendarController.selectedDay]
                    ?.map((st) => _trainingWidget(st))
                    ?.toList() ??
                [],
          ),
        ),
      ],
    );
  }
}
