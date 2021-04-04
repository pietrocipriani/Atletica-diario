import 'package:atletica/athlete_role/request_coach.dart';
import 'package:atletica/global_widgets/custom_calendar.dart';
import 'package:atletica/global_widgets/logout_button.dart';
import 'package:atletica/global_widgets/swap_button.dart';
import 'package:atletica/results/pbs/pbs_page_route.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/date.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:atletica/results/results_edit_dialog.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/allenamento.dart';
import 'package:atletica/training/training_description.dart';
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

  Widget _trainingWidget(final ScheduledTraining s) {
    final Result result = userA
        .getResults(Date.fromDateTime(controller.selectedDay))
        .firstWhere((r) => r.isCompatible(s), orElse: () => null);
    final Allenamento a = s.work;
    if (a == null) return Container();
    return CustomExpansionTile(
      title: a.name,
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() >= s.date
            ? () => showResultsEditDialog(
                  context,
                  result ?? Result.empty(a, s.date),
                  (r) => userA.saveResult(results: r),
                )
            : null,
        color: IconTheme.of(context).color,
      ),
      leading: Checkbox(
        value: result != null,
        fillColor:
            MaterialStateProperty.all(Theme.of(context).toggleableActiveColor),
        checkColor: Theme.of(context).colorScheme.onPrimary,
        onChanged: result == null
            ? (value) {
                userA.saveResult(
                  results: Result.empty(
                    s.work,
                    Date.fromDateTime(controller.selectedDay),
                  ),
                );
              }
            : result.isBooking
                ? (value) => result.reference.delete()
                : null,
      ),
      children: [
        if (a.descrizione != null)
          Text(
            a.descrizione,
            style: Theme.of(context)
                .textTheme
                .overline
                .copyWith(fontWeight: FontWeight.normal),
            textAlign: TextAlign.justify,
          ),
        const SizedBox(height: 10),
      ]
          .followedBy(TrainingDescription.fromTraining(
              context, a, a.variants.first, result)) // TODO: select variant
          .toList(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40),
    );
  }

  Widget _resultWidget(final Result result) {
    if (result?.training == null) return Container();
    return CustomExpansionTile(
      title: '${result.training} (prev)',
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() >= result.date
            ? () => showResultsEditDialog(
                  context,
                  result,
                  (r) => userA.saveResult(results: r),
                )
            : null,
        color: IconTheme.of(context).color,
      ),
      leading: Checkbox(
        value: true,
        onChanged: null,
        fillColor:
            MaterialStateProperty.all(Theme.of(context).toggleableActiveColor),
        checkColor: Theme.of(context).colorScheme.onPrimary,
      ),
      children: TrainingDescription.fromResults(context, result).toList(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40),
      /*trailing: IconButton(
        icon: Icon(Icons.play_arrow),
        onPressed: () {},
        color: Colors.black,
      ),*/
    );
  }

  bool _isOrphan(final Result result) {
    if (userA.events[controller.selectedDay]
            ?.any((st) => result.isCompatible(st, true)) ??
        false) return false;
    return userA.events[controller.selectedDay]
            ?.every(result.isNotCompatible) ??
        true;
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
    final ThemeData theme = Theme.of(context);
    //final ScheduledTraining compatibleST = _compatibleST;
    final Iterable<Result> orphans = controller.selectedDay == null
        ? []
        : userA
            .getResults(Date.fromDateTime(controller.selectedDay))
            .where(_isOrphan);
    List<Widget> children = orphans.map(_resultWidget).toList();
    if (userA.events[controller.selectedDay] != null)
      children = children
          .followedBy(userA.events[controller.selectedDay]
              ?.where((st) =>
                  st.athletes.isEmpty ||
                  st.athletes.contains(userA.athleteCoachReference))
              ?.cast<ScheduledTraining>()
              ?.map(_trainingWidget))
          .toList();

    final CustomCalendar calendar = CustomCalendar(
      controller: controller,
      events: userA.events,
      onDaySelected: (d, evts, holidays) => setState(() {}),
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
          : Padding(
              padding: MediaQuery.of(context).padding,
              child: Row(children: [
                AspectRatio(child: calendar, aspectRatio: 1),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
                  width: 1,
                  color: theme.disabledColor,
                ),
                Expanded(
                  child: ListView(
                    children: children,
                    padding: const EdgeInsets.all(0),
                  ),
                ),
              ]),
            );

      return Scaffold(
        appBar: orientation == Orientation.portrait
            ? AppBar(
                title: Text('Atletica - Atleta'),
                actions: [
                  IconButton(
                    icon: Icon(Mdi.podium),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PbsPageRoute()),
                      );
                    },
                  ),
                  LogoutButton(context: context),
                  SwapButton(context: context),
                ],
              )
            : null,
        body: body,
      );
    });
  }
}
