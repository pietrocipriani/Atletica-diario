import 'package:atletica/global_widgets/custom_calendar.dart';
import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/global_widgets/logout_button.dart';
import 'package:atletica/global_widgets/runas_button.dart';
import 'package:atletica/global_widgets/swap_button.dart';
import 'package:atletica/results/pbs/pbs_page_route.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/date.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/results/results_edit_dialog.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/training_description.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

abstract class CustomMainPage<T extends Object> extends StatefulWidget {
  final List<T> Function(Date dt) events;
  final Widget Function(T) eventBuilder;
  final String section;

  CustomMainPage({
    required this.events,
    required this.eventBuilder,
    required this.section,
  });

  @override
  _CustomMainPageState createState() => _CustomMainPageState();
}

class _CustomMainPageState<T extends CustomMainPage> extends State<T> {
  Date __selectedDay = Date.now();
  Date get _selectedDay => __selectedDay;
  set _selectedDay(final Date dt) {
    __selectedDay = dt;
  }

  late final Callback _callback = Callback((v, c) => setState(() {}));

  @override
  void initState() {
    Result.signInGlobal(_callback);
    ScheduledTraining.signInGlobal(_callback);
    super.initState();
  }

  @override
  void dispose() {
    Result.signOutGlobal(_callback.stopListening);
    ScheduledTraining.signOutGlobal(_callback);
    super.dispose();
  }

  Iterable<Widget> get widgets =>
      widget.events(_selectedDay).map(widget.eventBuilder);

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = widgets.toList();

    final CustomCalendar calendar = CustomCalendar(
      events: widget.events,
      selectedDay: _selectedDay,
      onDaySelected: (d, focused) => setState(() => _selectedDay = d),
    );
    final Widget eventsWidgets = Expanded(child: ListView(children: children));

    final List<IconButton> actions = [
      IconButton(
        icon: Icon(Mdi.podium),
        tooltip: 'RISULTATI',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PbsPageRoute()),
          );
        },
      ),
      LogoutButton(context: context),
      SwapButton(context: context),
      if (user.admin) RunasButton(context: context),
    ];

    return OrientationBuilder(builder: (context, orientation) {
      final Widget body = orientation == Orientation.portrait
          ? Column(children: [calendar, Divider(), eventsWidgets])
          : Row(children: [
              Padding(
                padding: MediaQuery.of(context).padding,
                child: AspectRatio(child: calendar, aspectRatio: 1),
              ),
              VerticalDivider(),
              eventsWidgets
            ]);

      return Scaffold(
        appBar: orientation == Orientation.portrait
            ? AppBar(
                title: Text('Atletica - ${widget.section}'),
                actions: actions,
              )
            : null,
        drawer: orientation == Orientation.landscape
            ? Drawer(
                child: ListView(
                  padding: MediaQuery.of(context).padding,
                  children: actions
                      .map((a) => CustomListTile(
                            leading: a,
                            title: Text(a.tooltip ?? ''),
                            onTap: a.onPressed,
                          ))
                      .toList(),
                ),
              )
            : null,
        body: body,
      );
    });
  }
}

class TrainingWidget extends StatefulWidget {
  final ScheduledTraining scheduledTraining;
  final Result? result;
  final bool checkbox;
  TrainingWidget({
    required this.scheduledTraining,
    this.result,
    this.checkbox = false,
  });

  @override
  _TrainingWidgetState createState() => _TrainingWidgetState();
}

class _TrainingWidgetState extends State<TrainingWidget> {
  late final Callback<Result> _callback = Callback((r, c) => setState(() {}));

  @override
  void initState() {
    widget.result?.signIn(_callback);
    super.initState();
  }

  @override
  void dispose() {
    widget.result?.signOut(_callback.stopListening);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Training? a = widget.scheduledTraining.work;
    if (a == null) return Container();

    final ThemeData theme = Theme.of(context);

    return CustomExpansionTile(
      title: a.name,
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() >= widget.scheduledTraining.date
            ? () => showResultsEditDialog(
                  context,
                  widget.result ??
                      Result.temp(a, widget.scheduledTraining.date),
                  userA.saveResult,
                )
            : null,
        color: theme.iconTheme.color,
      ),
      leading: widget.checkbox
          ? Checkbox(
              value: widget.result != null,
              fillColor: MaterialStateProperty.all(theme.toggleableActiveColor),
              checkColor: theme.colorScheme.onPrimary,
              onChanged: widget.result == null
                  ? (value) => userA.saveResult(Result.temp(
                        widget.scheduledTraining.work!,
                        widget.scheduledTraining.date,
                      ))
                  : widget.result?.isBooking ?? true
                      ? (value) => widget.result?.reference?.delete()
                      : null,
            )
          : null,
      children: <Widget>[
        if (a.descrizione.isNotEmpty)
          Align(
            alignment: Alignment.center,
            child: Text(
              a.descrizione,
              style: theme.textTheme.overline!
                  .copyWith(fontWeight: FontWeight.normal),
              textAlign: TextAlign.justify,
            ),
          ),
        const SizedBox(height: 10),
      ]
          .followedBy(TrainingDescription.fromTraining(
              a, a.variants.first, widget.result))
          .toList(growable: false),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
    );
  }
}
