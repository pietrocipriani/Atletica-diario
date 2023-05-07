import 'package:atletica/date.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomCalendar extends StatefulWidget {
  final List<Object> Function(Date dt) events;
  final void Function(Date d, DateTime focused)? onDaySelected;
  final void Function(PageController controller)? onCalendarCreated;
  final Date selectedDay;

  CustomCalendar({
    required this.events,
    required this.selectedDay,
    this.onDaySelected,
    this.onCalendarCreated,
  });

  @override
  _CustomCalendarState createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late Date _selected = widget.selectedDay;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return TableCalendar(
      focusedDay: _selected,
      currentDay: DateTime.now(),
      firstDay: DateTime(2020),
      lastDay: DateTime.now().add(Duration(days: 365)),
      availableCalendarFormats: {
        CalendarFormat.month: 'mese',
        CalendarFormat.week: 'settimana',
      },
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
        todayDecoration: BoxDecoration(
          color: theme.primaryColorLight,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: theme.primaryColorDark,
          shape: BoxShape.circle,
        ),
        markerSize: 5,
        markersMaxCount: 6,
        weekendTextStyle: TextStyle(color: theme.errorColor),
        todayTextStyle: const TextStyle(),
        outsideTextStyle: TextStyle(color: theme.disabledColor),
      ),
      locale: Localizations.localeOf(context).toLanguageTag(),
      startingDayOfWeek: StartingDayOfWeek.monday,
      weekendDays: [DateTime.sunday],
      headerStyle: HeaderStyle(
        formatButtonShowsNext: false,
        formatButtonVisible: false,
        titleCentered: true,
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: theme.textTheme.labelSmall!,
        weekendStyle: theme.textTheme.labelSmall!,
      ),
      eventLoader: (dt) => widget.events(Date.fromDateTime(dt)),
      onDaySelected: (d, f) {
        _selected = Date.fromDateTime(d);
        widget.onDaySelected?.call(_selected, f);
      },
      selectedDayPredicate: (day) => _selected == day,
      onCalendarCreated: widget.onCalendarCreated,
    );
  }
}
