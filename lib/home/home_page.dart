import 'package:atletica/global_widgets/custom_calendar.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/user_helper/coach_helper.dart';
import 'package:atletica/results/results.dart';
import 'package:atletica/results/results_edit_route.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/allenamento.dart';
import 'package:atletica/training/training_description.dart';
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
    if (a == null) return Container();
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
                Results(training: a, date: s.date, athletes: s.athletes),
              ),
            )),
        color: IconTheme.of(context).color,
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
    final ThemeData theme = Theme.of(context);
    return Column(
      children: [
        CustomCalendar(
          controller: _calendarController,
          onDaySelected: (day, events, holidays) =>
              widget.onSelectedDayChanged?.call(day),
          onCalendarCreated: (first, last, format) => widget
              .onSelectedDayChanged
              ?.call(_calendarController.selectedDay),
          events: userC?.scheduledTrainings ?? {},
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          height: 1,
          color: theme.disabledColor,
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
