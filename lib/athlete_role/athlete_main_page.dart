import 'package:atletica/athlete_role/request_coach.dart';
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
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:atletica/results/results_edit_dialog.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/training_description.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

class AthleteMainPage extends StatefulWidget {
  @override
  _AthleteMainPageState createState() => _AthleteMainPageState();
}

class _AthleteMainPageState extends State<AthleteMainPage> {
  Date selectedDay = Date.now();
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

  bool _isOrphan(final Result result) {
    if (userA.events[selectedDay]?.any((st) => result.isCompatible(st, true)) ??
        false) return false;
    return userA.events[selectedDay]?.every(result.isNotCompatible) ?? true;
  }

  void pushRequest() {
    WidgetsBinding.instance!.addPostFrameCallback(
      (_) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RequestCoachRoute()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!userA.hasCoach) pushRequest();
    final ThemeData theme = Theme.of(context);
    //final ScheduledTraining compatibleST = _compatibleST;
    final Iterable<Result> orphans =
        userA.getResults(selectedDay).where(_isOrphan);
    List<Widget> children =
        orphans.map<Widget>((r) => _ResultWidget(r)).toList();
    if (userA.events[selectedDay] != null)
      children = children
          .followedBy(userA.events[selectedDay]
                  ?.where((st) =>
                      st.athletes.isEmpty ||
                      st.athletes.contains(userA.athleteCoachReference))
                  .cast<ScheduledTraining>()
                  .map((s) => _TrainingWidget(s)) ??
              [])
          .toList();

    final CustomCalendar calendar = CustomCalendar(
      events: userA.events,
      onDaySelected: (d, focused) =>
          setState(() => selectedDay = Date.fromDateTime(d)),
    );

    return OrientationBuilder(builder: (context, orientation) {
      final Widget body = orientation == Orientation.portrait
          ? Column(children: [
              calendar,
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                height: 1,
                color: theme.disabledColor,
              ),
              Expanded(child: ListView(children: children)),
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
              Expanded(child: ListView(children: children)),
            ]);

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

      return Scaffold(
        appBar: orientation == Orientation.portrait
            ? AppBar(
                title: Text('Atletica - Atleta'),
                actions: actions,
              )
            : null,
        drawer: orientation == Orientation.landscape
            ? Drawer(
                child: Padding(
                  padding: MediaQuery.of(context).padding,
                  child: Column(
                    children: actions
                        .map((a) => CustomListTile(
                              leading: a,
                              title: Text(a.tooltip ?? ''),
                              onTap: a.onPressed,
                            ))
                        .toList(),
                  ),
                ),
              )
            : null,
        body: body,
      );
    });
  }
}

class _TrainingWidget extends StatelessWidget {
  final ScheduledTraining s;
  _TrainingWidget(this.s);

  static final _null = Container();
  static TextStyle? overlineNormal;

  @override
  Widget build(BuildContext context) {
    final List<Result> results = userA.getResults(s.date).toList();
    final Training? a = s.work;
    if (a == null) return _null;
    final Result? result = () {
      try {
        return results.firstWhere(
          (r) => r.isCompatible(s, true),
          orElse: () => results.firstWhere((r) => r.isCompatible(s)),
        );
      } on StateError catch (_) {
        return null;
      }
    }();
    final ThemeData theme = Theme.of(context);
    overlineNormal ??=
        theme.textTheme.overline!.copyWith(fontWeight: FontWeight.normal);

    return CustomExpansionTile(
      title: a.name,
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() >= s.date
            ? () => showResultsEditDialog(
                  context,
                  result ?? Result.empty(a, s.date),
                  userA.saveResult,
                )
            : null,
        color: theme.iconTheme.color,
      ),
      leading: Checkbox(
        value: result != null,
        fillColor: MaterialStateProperty.all(theme.toggleableActiveColor),
        checkColor: theme.colorScheme.onPrimary,
        onChanged: result == null
            ? (value) => userA.saveResult(Result.empty(s.work!, s.date))
            : result.isBooking
                ? (value) => result.reference?.delete()
                : null,
      ),
      children: <Widget>[
        if (a.descrizione.isNotEmpty)
          Align(
            alignment: Alignment.center,
            child: Text(
              a.descrizione,
              style: overlineNormal,
              textAlign: TextAlign.justify,
            ),
          ),
        const SizedBox(height: 10),
      ]
          .followedBy(TrainingDescription.fromTraining(
              context, a, a.variants.first, result))
          .toList(growable: false),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40),
    );
  }
}

class _ResultWidget extends StatelessWidget {
  final Result _result;
  _ResultWidget(this._result);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return CustomExpansionTile(
      title: '${_result.training} (prev)',
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() >= _result.date
            ? () => showResultsEditDialog(context, _result, userA.saveResult)
            : null,
        color: theme.iconTheme.color,
      ),
      leading: Checkbox(
        value: true,
        onChanged: null,
        fillColor: MaterialStateProperty.all(theme.toggleableActiveColor),
        checkColor: theme.colorScheme.onPrimary,
      ),
      children: TrainingDescription.fromResults(context, _result).toList(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40),
    );
  }
}
