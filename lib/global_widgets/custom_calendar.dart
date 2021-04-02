import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomCalendar extends StatelessWidget {
  final CalendarController controller;
  final Map<DateTime, List> events;
  final void Function(DateTime d, List events, List holidays) onDaySelected;
  final void Function(DateTime first, DateTime last, CalendarFormat format)
      onCalendarCreated;

  CustomCalendar({
    @required this.controller,
    @required this.events,
    this.onDaySelected,
    this.onCalendarCreated,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return TableCalendar(
      calendarController: controller,
      availableCalendarFormats: {
        CalendarFormat.month: 'mese',
        CalendarFormat.week: 'settimana',
      },
      calendarStyle: CalendarStyle(
        selectedColor: theme.primaryColor,
        todayColor: theme.primaryColorLight,
        markersColor: theme.primaryColorDark,
        todayStyle: const TextStyle(),
        outsideStyle: TextStyle(color: theme.disabledColor),
        outsideWeekendStyle: TextStyle(color: Colors.red.withOpacity(0.3)),
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
        weekdayStyle: theme.textTheme.overline,
        weekendStyle: theme.textTheme.overline,
      ),
      events: events,
      onDaySelected: onDaySelected,
      onCalendarCreated: onCalendarCreated,
    );
  }
}
