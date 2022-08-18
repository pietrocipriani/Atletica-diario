import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/date.dart';
import 'package:atletica/global_widgets/custom_calendar.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/results/results.dart';
import 'package:atletica/results/results_edit_route.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/training_description.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

class HomePageWidget extends StatefulWidget {
  final void Function(Date day)? onSelectedDayChanged;
  final Orientation orientation;

  HomePageWidget({
    Key? key,
    this.onSelectedDayChanged,
    this.orientation = Orientation.portrait,
  }) : super(key: key);

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  Date selectedDay = Date.now();
  late final Callback callback = Callback((_, c) => setState(() {}));

  /// must listen `onAthleteCallbacks` because insertion/removal
  /// can change schedule's disponibility
  /// ```
  /// Iterable<Schedule> get avaiableSchedules =>
  ///   schedules.values.where((s) => s.athletes.isNotEmpty && s.isValid);
  /// ```
  @override
  void initState() {
    ScheduledTraining.signInGlobal(callback);
    Athlete.signInGlobal(callback);
    super.initState();
  }

  @override
  void dispose() {
    ScheduledTraining.signOutGlobal(callback.stopListening);
    Athlete.signOutGlobal(callback);
    super.dispose();
  }

  Widget _trainingWidget(final ScheduledTraining s) {
    final Training? a = s.work;
    if (a == null) return Container();
    return CustomExpansionTile(
      title: a.name,
      subtitle: s.athletes.isEmpty
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
      children: TrainingDescription.fromTraining(a).toList(), // TODO: select variant
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
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
    final CustomCalendar calendar = CustomCalendar(
      onDaySelected: (day, focused) {
        widget.onSelectedDayChanged?.call(day);
        setState(() => selectedDay = day);
      },
      selectedDay: selectedDay,
      onCalendarCreated: (controller) => widget.onSelectedDayChanged?.call(selectedDay),
      events: (dt) => ScheduledTraining.ofDate(dt),
    );
    final Widget list = Expanded(
      child: ListView(
        children: ScheduledTraining.ofDate(selectedDay).map((st) => _trainingWidget(st)).toList(),
      ),
    );

    return widget.orientation == Orientation.portrait
        ? Column(children: [
            calendar,
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              height: 1,
              color: theme.disabledColor,
            ),
            list
          ])
        : Row(children: [
            Padding(
              padding: MediaQuery.of(context).padding,
              child: AspectRatio(child: calendar, aspectRatio: 1),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
              width: 1,
              color: theme.disabledColor,
            ),
            list
          ]);
  }
}
