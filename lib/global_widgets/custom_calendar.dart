import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomCalendar extends StatelessWidget {
  final Map<DateTime, List> events;
  final void Function(DateTime d, DateTime focused)? onDaySelected;
  final void Function(PageController controller)? onCalendarCreated;

  CustomCalendar({
    required this.events,
    this.onDaySelected,
    this.onCalendarCreated,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return TableCalendar(
      focusedDay: DateTime.now(),
      firstDay: DateTime(2020),
      lastDay: DateTime.now().add(Duration(days: 365)),
      availableCalendarFormats: {
        CalendarFormat.month: 'mese',
        CalendarFormat.week: 'settimana',
      },
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(color: theme.primaryColor),
        todayDecoration: BoxDecoration(color: theme.primaryColorLight),
        markerDecoration: BoxDecoration(color: theme.primaryColorDark),
        todayTextStyle: const TextStyle(),
        outsideTextStyle: TextStyle(color: theme.disabledColor),
      ),
      locale: 'it',
      startingDayOfWeek: StartingDayOfWeek.monday,
      weekendDays: [DateTime.sunday],
      headerStyle: HeaderStyle(
        formatButtonShowsNext: false,
        formatButtonVisible: false,
        titleCentered: true,
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: theme.textTheme.overline!,
        weekendStyle: theme.textTheme.overline!,
      ),
      eventLoader: (dt) => events[dt] ?? [],
      onDaySelected: onDaySelected,
      onCalendarCreated: onCalendarCreated,
    );
  }
}
